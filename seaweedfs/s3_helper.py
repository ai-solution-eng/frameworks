#!/usr/bin/env python3
"""SeaweedFS S3 helper - bucket, upload, download and read objects from Python or the shell.

The S3 endpoint is a single host with no wildcard DNS, so **path-style addressing is
mandatory** and is baked into the client below. Everything else is ordinary boto3.

Configuration (environment, all optional except the first three):

    S3_ENDPOINT    https://seaweedfs-s3.<domain>      public host, or
                   http://seaweedfs-s3.<ns>.svc.cluster.local:8333  from inside the cluster
    S3_ACCESS_KEY  seaweedfs
    S3_SECRET_KEY  the secretKey from the s3-config / s3-identity Secret
    S3_CA_BUNDLE   path to the AIE Root CA, when the gateway cert is not publicly trusted
    S3_REGION      default us-east-1. SigV4 puts the region inside the credential scope,
                   and SeaweedFS re-derives from whatever the client sent, so any value is
                   accepted (verified: eu-central-1 works against a us-east-1 deployment).
                   It only has to be self-consistent - keep one value so clients stay
                   comparable, since a drift to another region produces no error at all.

fish setup against a PCAI deployment:

    set -gx S3_ENDPOINT https://seaweedfs-s3.pcai-se-ai-application.hst.rdlabs.hpecorp.net
    set -gx S3_ACCESS_KEY seaweedfs
    set -gx S3_SECRET_KEY (ksea get secret seaweedfs-s3-identity -o jsonpath='{.data.seaweedfs_s3_config}' | base64 -d | jq -r '.identities[0].credentials[0].secretKey')
    set -gx S3_CA_BUNDLE ~/.dsh/certs/pcai-aie-root-ca.crt

bash setup:  export S3_ENDPOINT=... S3_ACCESS_KEY=... S3_SECRET_KEY=... S3_CA_BUNDLE=...

Shell use:

    python3 s3_helper.py buckets                          # list buckets
    python3 s3_helper.py mkdir andrew-bucket              # create a bucket (idempotent)
    python3 s3_helper.py put ./paper.pdf andrew-bucket/LLM_Papers/paper.pdf
    python3 s3_helper.py putdir ./LLM_Papers andrew-bucket/LLM_Papers
    python3 s3_helper.py ls andrew-bucket                 # prefix listing
    python3 s3_helper.py cat andrew-bucket/notes.md       # print an object
    python3 s3_helper.py get andrew-bucket/notes.md ./notes.md
    python3 s3_helper.py rm andrew-bucket/notes.md
    python3 s3_helper.py rmbucket andrew-bucket

Library use:

    from s3_helper import create_bucket, upload_file, upload_folder, download_file, cat_object
    create_bucket("andrew-bucket")
    upload_folder("./LLM_Papers", "andrew-bucket", prefix="LLM_Papers")

Notes:
  * a bucket created in the filer UI (a directory under /buckets) is the same object as one
    created through the S3 API, so both show up in list_buckets().
  * uploads go through the boto3 transfer manager, so anything over 8 MiB is multipart
    automatically - which is what the no-timeout, no-retry S3 route expects.
  * deleting objects does not immediately free space: the volume server reclaims it during
    compaction (see documentation/OPERATIONS.md).
"""
from __future__ import annotations

import argparse
import fnmatch
import os
import signal
import sys
import time
from typing import Iterable, Iterator

try:
    import boto3
    from boto3.s3.transfer import TransferConfig
    from botocore.config import Config
    from botocore.exceptions import BotoCoreError, ClientError, EndpointConnectionError
except ImportError:  # pragma: no cover - dependency check
    sys.exit("boto3 is not installed:  pip install boto3")

DEFAULT_EXCLUDES = (
    ".git/*", ".git", "__pycache__/*", "*.pyc", ".DS_Store", "*.swp", ".venv/*", "node_modules/*",
)
MULTIPART_THRESHOLD = 8 * 1024 * 1024
MULTIPART_CHUNKSIZE = 8 * 1024 * 1024


# --------------------------------------------------------------------------- client
def client():
    """Build a path-style S3 client from the environment."""
    endpoint = os.environ.get("S3_ENDPOINT")
    access = os.environ.get("S3_ACCESS_KEY", "seaweedfs")
    secret = os.environ.get("S3_SECRET_KEY")
    if not endpoint:
        sys.exit("S3_ENDPOINT is not set (e.g. https://seaweedfs-s3.<domain>)")
    if not secret:
        sys.exit("S3_SECRET_KEY is not set - read it from the identity Secret")
    ca = os.environ.get("S3_CA_BUNDLE") or None
    return boto3.client(
        "s3",
        endpoint_url=endpoint,
        aws_access_key_id=access,
        aws_secret_access_key=secret,
        region_name=os.environ.get("S3_REGION", "us-east-1"),
        config=Config(
            signature_version="s3v4",
            s3={"addressing_style": "path"},   # mandatory: one host, no wildcard DNS
            retries={"max_attempts": 3, "mode": "standard"},
            connect_timeout=10,
            read_timeout=300,
        ),
        verify=ca if ca else True,
    )


# --------------------------------------------------------------------------- buckets
def create_bucket(name: str, s3=None) -> bool:
    """Create a bucket. Returns True if created, False if it already existed."""
    s3 = s3 or client()
    try:
        s3.create_bucket(Bucket=name)
        return True
    except ClientError as exc:
        code = exc.response["Error"]["Code"]
        if code in ("BucketAlreadyOwnedByYou", "BucketAlreadyExists"):
            return False
        raise


def list_buckets(s3=None) -> list[str]:
    s3 = s3 or client()
    return [b["Name"] for b in s3.list_buckets().get("Buckets", [])]


def delete_bucket(name: str, s3=None) -> None:
    s3 = s3 or client()
    s3.delete_bucket(Bucket=name)


# --------------------------------------------------------------------------- upload
def upload_file(local_path: str, bucket: str, key: str | None = None, s3=None) -> str:
    """Upload one file. Returns the object key."""
    s3 = s3 or client()
    key = key or os.path.basename(local_path)
    s3.upload_file(
        local_path, bucket, key,
        Config=TransferConfig(
            multipart_threshold=MULTIPART_THRESHOLD,
            multipart_chunksize=MULTIPART_CHUNKSIZE,
        ),
    )
    return key


def _iter_files(root: str, excludes: Iterable[str]) -> Iterator[tuple[str, str]]:
    """Yield (absolute path, path relative to root), honouring the exclude globs."""
    patterns = tuple(excludes)
    for dirpath, dirnames, filenames in os.walk(root):
        rel_dir = os.path.relpath(dirpath, root)
        dirnames[:] = [
            d for d in dirnames
            if not _excluded(os.path.join(rel_dir, d) if rel_dir != "." else d, patterns)
        ]
        for name in sorted(filenames):
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, root)
            if _excluded(rel, patterns):
                continue
            yield full, rel


def _excluded(rel_path: str, patterns: tuple[str, ...]) -> bool:
    rel_path = rel_path.replace(os.sep, "/")
    return any(
        fnmatch.fnmatch(rel_path, p) or fnmatch.fnmatch(os.path.basename(rel_path), p)
        for p in patterns
    )


def upload_folder(
    local_dir: str,
    bucket: str,
    prefix: str = "",
    excludes: Iterable[str] = DEFAULT_EXCLUDES,
    dry_run: bool = False,
    quiet: bool = False,
    s3=None,
) -> dict:
    """Upload a directory tree. Returns {'uploaded': n, 'bytes': n, 'skipped': n, 'failed': [...]}"""
    s3 = s3 or client()
    prefix = prefix.strip("/")
    stats = {"uploaded": 0, "bytes": 0, "skipped": 0, "failed": []}
    if not os.path.isdir(local_dir):
        raise NotADirectoryError(local_dir)

    for full, rel in _iter_files(local_dir, excludes):
        key = f"{prefix}/{rel}".lstrip("/") if prefix else rel
        key = key.replace(os.sep, "/")
        size = os.path.getsize(full)
        if dry_run:
            print(f"would upload {rel} -> {bucket}/{key} ({_human(size)})")
            stats["skipped"] += 1
            continue
        try:
            started = time.time()
            upload_file(full, bucket, key, s3=s3)
            stats["uploaded"] += 1
            stats["bytes"] += size
            if not quiet:
                print(f"  {_human(size):>9}  {time.time() - started:5.1f}s  {bucket}/{key}")
        except (ClientError, BotoCoreError) as exc:
            stats["failed"].append((rel, str(exc)))
            print(f"  FAILED {rel}: {exc}", file=sys.stderr)
    return stats


# --------------------------------------------------------------------------- read
def list_objects(bucket: str, prefix: str = "", limit: int = 0, s3=None) -> list[dict]:
    """List objects, recursively, under a prefix."""
    s3 = s3 or client()
    kwargs = {"Bucket": bucket, "Prefix": prefix}
    out: list[dict] = []
    while True:
        page = s3.list_objects_v2(**kwargs)
        for obj in page.get("Contents", []):
            out.append(obj)
            if limit and len(out) >= limit:
                return out
        if not page.get("IsTruncated"):
            return out
        kwargs["ContinuationToken"] = page["NextContinuationToken"]


def download_file(bucket: str, key: str, local_path: str | None = None, s3=None) -> str:
    """Copy an object to the local filesystem. Returns the path written."""
    s3 = s3 or client()
    target = local_path or os.path.basename(key)
    parent = os.path.dirname(os.path.abspath(target))
    os.makedirs(parent, exist_ok=True)
    s3.download_file(bucket, key, target)
    head = s3.head_object(Bucket=bucket, Key=key)
    got = os.path.getsize(target)
    if got != head["ContentLength"]:
        raise IOError(f"size mismatch: got {got}, expected {head['ContentLength']}")
    return target


def cat_object(bucket: str, key: str, max_bytes: int = 0, binary: bool = False, s3=None) -> int:
    """Stream an object to stdout. Returns the number of bytes written."""
    s3 = s3 or client()
    body = s3.get_object(Bucket=bucket, Key=key)["Body"]
    written = 0
    out = sys.stdout.buffer if binary else sys.stdout
    while True:
        chunk = body.read(64 * 1024)
        if not chunk:
            break
        if max_bytes and written + len(chunk) > max_bytes:
            chunk = chunk[: max_bytes - written]
        if binary:
            out.write(chunk)
        else:
            out.write(chunk.decode("utf-8", errors="replace"))
        written += len(chunk)
        if max_bytes and written >= max_bytes:
            if not binary:
                out.write(f"\n... truncated at {max_bytes} bytes (use --all to stream the rest)\n")
            break
    if not binary:
        out.flush()
    return written


def verify_folder(
    local_dir: str,
    bucket: str,
    prefix: str = "",
    excludes: Iterable[str] = DEFAULT_EXCLUDES,
    s3=None,
) -> dict:
    """Compare a local tree against a bucket prefix: count, names and byte sizes.

    This is the close-out check for an ingest window - the customer's manifest is the
    local tree, and anything missing or short here is data that did not land.
    """
    s3 = s3 or client()
    prefix = prefix.strip("/")
    remote = {
        obj["Key"]: obj["Size"]
        for obj in list_objects(bucket, prefix=f"{prefix}/" if prefix else "", s3=s3)
    }
    local = {
        (f"{prefix}/{rel}".lstrip("/") if prefix else rel).replace(os.sep, "/"): os.path.getsize(full)
        for full, rel in _iter_files(local_dir, excludes)
    }
    missing = sorted(k for k in local if k not in remote)
    short = sorted(
        (k, local[k], remote[k]) for k in local
        if k in remote and remote[k] != local[k]
    )
    extra = sorted(k for k in remote if k not in local)
    return {
        "local_files": len(local),
        "local_bytes": sum(local.values()),
        "remote_files": len(remote),
        "remote_bytes": sum(remote.values()),
        "missing": missing,
        "size_mismatch": short,
        "extra_remote": extra,
    }


def presign(bucket: str, key: str, expires: int = 3600, s3=None) -> str:
    """A presigned GET URL. Valid only against the host it was signed for."""
    s3 = s3 or client()
    return s3.generate_presigned_url("get_object", Params={"Bucket": bucket, "Key": key}, ExpiresIn=expires)


# --------------------------------------------------------------------------- delete
def delete_object(bucket: str, key: str, s3=None) -> None:
    (s3 or client()).delete_object(Bucket=bucket, Key=key)


# --------------------------------------------------------------------------- helpers
def _human(n: float) -> str:
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if n < 1024 or unit == "TiB":
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} TiB"


def describe_config() -> dict:
    """Effective configuration, with the secret masked. No network calls."""
    endpoint = os.environ.get("S3_ENDPOINT", "")
    access = os.environ.get("S3_ACCESS_KEY", "seaweedfs")
    secret = os.environ.get("S3_SECRET_KEY", "")
    ca = os.environ.get("S3_CA_BUNDLE", "")
    region = os.environ.get("S3_REGION", "us-east-1")
    masked = f"{secret[:4]}...{secret[-4:]} ({len(secret)} chars)" if len(secret) > 8 else ("set" if secret else "MISSING")
    return {
        "S3_ENDPOINT": endpoint or "MISSING",
        "S3_ACCESS_KEY": access,
        "S3_SECRET_KEY": masked,
        "S3_CA_BUNDLE": f"{ca} ({'exists' if os.path.isfile(ca) else 'NOT FOUND'})" if ca else "(unset - system trust store)",
        "S3_REGION": region,
    }


def _split_target(target: str) -> tuple[str, str]:
    """'bucket/key/path' -> ('bucket', 'key/path')"""
    if "/" not in target:
        raise SystemExit(f"expected <bucket>/<key>, got {target!r}")
    bucket, _, key = target.partition("/")
    if not key:
        raise SystemExit(f"expected <bucket>/<key>, got {target!r}")
    return bucket, key


# --------------------------------------------------------------------------- CLI
def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="SeaweedFS S3 helper (path-style, SigV4). Configure via S3_* env vars.",
    )
    parser.add_argument(
        "--region", default=None,
        help="override S3_REGION for this call (SigV4 credential scope; default us-east-1)",
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("buckets", help="list buckets")

    sub.add_parser("config", help="print the effective S3_* configuration (secret masked, no network)")
    sub.add_parser("ping", help="connect and list buckets - proves the settings work")

    p = sub.add_parser("mkdir", help="create a bucket (idempotent)")
    p.add_argument("bucket")

    p = sub.add_parser("rmbucket", help="delete an empty bucket")
    p.add_argument("bucket")

    p = sub.add_parser("put", help="upload one file: put <local-file> <bucket>/<key>")
    p.add_argument("source")
    p.add_argument("target")

    p = sub.add_parser("putdir", help="upload a folder: putdir <local-dir> <bucket>[/<prefix>]")
    p.add_argument("source")
    p.add_argument("target", help="<bucket> or <bucket>/<prefix>")
    p.add_argument("--exclude", action="append", default=None,
                   help="glob to skip (repeatable; defaults skip .git, __pycache__, .DS_Store ...)")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--quiet", action="store_true")

    p = sub.add_parser("ls", help="list objects: ls <bucket>[/<prefix>]")
    p.add_argument("target")
    p.add_argument("--limit", type=int, default=0)
    p.add_argument("--long", action="store_true", help="show size and mtime")

    p = sub.add_parser("verify", help="compare a local tree against a bucket prefix")
    p.add_argument("source")
    p.add_argument("target", help="<bucket> or <bucket>/<prefix>")
    p.add_argument("--exclude", action="append", default=None)
    p.add_argument("--strict", action="store_true", help="also fail on objects present only in the bucket")

    p = sub.add_parser("get", help="download an object: get <bucket>/<key> [local-path]")
    p.add_argument("target")
    p.add_argument("local_path", nargs="?")

    p = sub.add_parser("cat", help="print an object: cat <bucket>/<key>")
    p.add_argument("target")
    p.add_argument("--all", action="store_true", help="stream the whole object (default caps at 1 MiB)")
    p.add_argument("--binary", action="store_true", help="write raw bytes instead of text")

    p = sub.add_parser("presign", help="presigned GET URL: presign <bucket>/<key>")
    p.add_argument("target")
    p.add_argument("--expires", type=int, default=3600)

    p = sub.add_parser("rm", help="delete one object: rm <bucket>/<key>")
    p.add_argument("target")

    args = parser.parse_args(argv)
    if args.region:
        os.environ["S3_REGION"] = args.region

    try:
        if args.cmd == "buckets":
            names = list_buckets()
            print("\n".join(names) if names else "(no buckets)")
            return 0

        if args.cmd == "config":
            cfg = describe_config()
            width = max(len(k) for k in cfg)
            for key, value in cfg.items():
                print(f"{key:<{width}}  {value}")
            if "MISSING" in cfg["S3_ENDPOINT"] or "MISSING" in cfg["S3_SECRET_KEY"]:
                print("\nS3_ENDPOINT and S3_SECRET_KEY are required - see the docstring at the top of this file.",
                      file=sys.stderr)
                return 1
            return 0

        if args.cmd == "ping":
            names = list_buckets()
            print(f"OK  {os.environ.get('S3_ENDPOINT')}  ({len(names)} bucket(s))")
            return 0

        if args.cmd == "mkdir":
            created = create_bucket(args.bucket)
            print(f"{'created' if created else 'already exists'}: {args.bucket}")
            return 0

        if args.cmd == "rmbucket":
            delete_bucket(args.bucket)
            print(f"deleted: {os.environ.get('S3_ENDPOINT')} {args.bucket}")
            return 0

        if args.cmd == "put":
            bucket, key = _split_target(args.target)
            size = os.path.getsize(args.source)
            key = upload_file(args.source, bucket, key)
            print(f"uploaded {_human(size)} -> {bucket}/{key}")
            return 0

        if args.cmd == "putdir":
            bucket, _, prefix = args.target.partition("/")
            excludes = tuple(args.exclude) if args.exclude else DEFAULT_EXCLUDES
            stats = upload_folder(
                args.source, bucket, prefix=prefix, excludes=excludes,
                dry_run=args.dry_run, quiet=args.quiet,
            )
            verb = "would upload" if args.dry_run else "uploaded"
            print(f"{verb} {stats['uploaded']} file(s), {_human(stats['bytes'])} to {args.target}")
            if stats["failed"]:
                print(f"{len(stats['failed'])} failed", file=sys.stderr)
                return 1
            return 0

        if args.cmd == "ls":
            bucket, _, prefix = args.target.partition("/")
            objects = list_objects(bucket, prefix, limit=args.limit)
            for obj in objects:
                if args.long:
                    print(f"{_human(obj['Size']):>10}  {obj['LastModified']:%Y-%m-%d %H:%M}  {obj['Key']}")
                else:
                    print(obj["Key"])
            print(f"-- {len(objects)} object(s), {_human(sum(o['Size'] for o in objects))}", file=sys.stderr)
            return 0

        if args.cmd == "verify":
            bucket, _, prefix = args.target.partition("/")
            excludes = tuple(args.exclude) if args.exclude else DEFAULT_EXCLUDES
            res = verify_folder(args.source, bucket, prefix=prefix, excludes=excludes)
            print(f"local : {res['local_files']:>6} file(s)  {_human(res['local_bytes']):>10}")
            print(f"remote: {res['remote_files']:>6} file(s)  {_human(res['remote_bytes']):>10}  ({bucket}/{prefix or ''})")
            for key in res["missing"]:
                print(f"  MISSING remote: {key}")
            for key, lsize, rsize in res["size_mismatch"]:
                print(f"  SIZE differs:   {key}  local {_human(lsize)} / remote {_human(rsize)}")
            if args.strict:
                for key in res["extra_remote"]:
                    print(f"  ONLY remote:    {key}")
            ok = not res["missing"] and not res["size_mismatch"] and not (args.strict and res["extra_remote"])
            print("VERIFIED - local and remote match" if ok else "DIFFERENCES FOUND", file=sys.stderr)
            return 0 if ok else 1

        if args.cmd == "get":
            bucket, key = _split_target(args.target)
            written = download_file(bucket, key, args.local_path)
            print(f"wrote {_human(os.path.getsize(written))} -> {written}")
            return 0

        if args.cmd == "cat":
            bucket, key = _split_target(args.target)
            cat_object(bucket, key, max_bytes=0 if args.all else 1024 * 1024, binary=args.binary)
            return 0

        if args.cmd == "presign":
            bucket, key = _split_target(args.target)
            print(presign(bucket, key, expires=args.expires))
            return 0

        if args.cmd == "rm":
            bucket, key = _split_target(args.target)
            delete_object(bucket, key)
            print(f"deleted: {os.environ.get('S3_ENDPOINT')} {bucket}/{key}")
            return 0

        parser.error(f"unknown command {args.cmd}")
    except EndpointConnectionError as exc:
        print(f"\nCONNECT FAILED - DNS/route/VirtualService problem:\n{exc}", file=sys.stderr)
        return 2
    except ClientError as exc:
        code = exc.response["Error"]["Code"]
        msg = exc.response["Error"].get("Message", "")
        print(f"\nS3 ERROR {code}: {msg}", file=sys.stderr)
        if code == "SignatureDoesNotMatch" or code == "InvalidAccessKeyId":
            print("  -> wrong key, or S3_CA_BUNDLE unset against a self-signed gateway", file=sys.stderr)
        if "CERTIFICATE_VERIFY_FAILED" in str(exc):
            print("  -> set S3_CA_BUNDLE to the AIE Root CA", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    # "cat ... | head" closes the pipe early; exit quietly instead of raising
    # BrokenPipeError from the interpreter's final flush.
    try:
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    except (AttributeError, ValueError):  # pragma: no cover - non-POSIX
        pass
    raise SystemExit(main())
