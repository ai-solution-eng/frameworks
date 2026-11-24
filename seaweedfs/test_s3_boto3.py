#!/usr/bin/env python3
"""Smoke-test the SeaweedFS S3 gateway with boto3.

Usage:
    export S3_SECRET_KEY=<the key you deployed with>
    python3 test_s3_boto3.py

Optional env:
    S3_ENDPOINT   default: the public VirtualService host
    S3_ACCESS_KEY default: seaweedfs
    S3_BUCKET     default: boto3-smoke
    S3_REGION     default: us-east-1

Notes:
  * path-style addressing is REQUIRED - the endpoint is a single host with no
    wildcard DNS/cert, so virtual-hosted style (bucket.host) cannot work.
  * the secret key is read from the environment only, never hardcoded.
"""
import os
import sys
import hashlib

try:
    import boto3
    from botocore.config import Config
    from botocore.exceptions import ClientError, EndpointConnectionError, BotoCoreError
    from boto3.s3.transfer import TransferConfig
except ImportError:
    sys.exit("boto3 is not installed:  pip install boto3")

ENDPOINT = os.environ.get(
    "S3_ENDPOINT", "https://seaweedfs-s3.pcai-se-ai-application.hst.rdlabs.hpecorp.net"
)
ACCESS_KEY = os.environ.get("S3_ACCESS_KEY", "seaweedfs")
SECRET_KEY = os.environ.get("S3_SECRET_KEY")
BUCKET = os.environ.get("S3_BUCKET", "boto3-smoke")
REGION = os.environ.get("S3_REGION", "us-east-1")
# PCAI gateways present a cert from the cluster-internal AIE Root CA, which is not
# in the system trust store. Point this at the CA file to verify properly.
CA_BUNDLE = os.environ.get("S3_CA_BUNDLE") or None

if not SECRET_KEY:
    sys.exit("set S3_SECRET_KEY first (the key from your helm --set-string)")

s3 = boto3.client(
    "s3",
    endpoint_url=ENDPOINT,
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY,
    region_name=REGION,
    config=Config(
        signature_version="s3v4",
        s3={"addressing_style": "path"},   # mandatory for a single-host endpoint
        retries={"max_attempts": 3, "mode": "standard"},
        connect_timeout=10,
        read_timeout=120,
    ),
    verify=CA_BUNDLE if CA_BUNDLE else True,
)


def step(name):
    print(f"\n== {name}")


def main():
    print(f"endpoint : {ENDPOINT}")
    print(f"bucket   : {BUCKET}")
    print(f"CA bundle: {CA_BUNDLE or '(system default)'}")

    step("1. create_bucket")
    try:
        s3.create_bucket(Bucket=BUCKET)
        print(f"   created {BUCKET}")
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in ("BucketAlreadyOwnedByYou", "BucketAlreadyExists"):
            print(f"   already exists ({code}) - continuing")
        else:
            raise

    step("2. put_object (small)")
    body = b"hello from boto3\n"
    s3.put_object(Bucket=BUCKET, Key="hello.txt", Body=body, ContentType="text/plain")
    print(f"   wrote hello.txt ({len(body)} bytes)")

    step("3. get_object + verify bytes")
    got = s3.get_object(Bucket=BUCKET, Key="hello.txt")["Body"].read()
    assert got == body, f"round-trip mismatch: {got!r}"
    print("   round-trip OK")

    step("4. list_objects_v2")
    keys = [o["Key"] for o in s3.list_objects_v2(Bucket=BUCKET).get("Contents", [])]
    print(f"   {len(keys)} object(s): {keys}")

    step("5. multipart upload (12 MiB) - exercises the gateway beyond a single PUT")
    big = os.urandom(12 * 1024 * 1024)
    with open("/tmp/_s3_multipart.bin", "wb") as f:
        f.write(big)
    s3.upload_file(
        "/tmp/_s3_multipart.bin",
        BUCKET,
        "multipart.bin",
        Config=TransferConfig(multipart_threshold=5 * 1024 * 1024, multipart_chunksize=5 * 1024 * 1024),
    )
    head = s3.head_object(Bucket=BUCKET, Key="multipart.bin")
    assert head["ContentLength"] == len(big), (head["ContentLength"], len(big))
    print(f"   multipart OK ({head['ContentLength']} bytes)")
    os.remove("/tmp/_s3_multipart.bin")

    step("6. presigned URL (optional - works only if the host is reachable by the client)")
    try:
        url = s3.generate_presigned_url(
            "get_object", Params={"Bucket": BUCKET, "Key": "hello.txt"}, ExpiresIn=300
        )
        print(f"   {url[:110]}...")
    except BotoCoreError as e:
        print(f"   skipped: {e}")

    step("7. cleanup")
    s3.delete_object(Bucket=BUCKET, Key="hello.txt")
    s3.delete_object(Bucket=BUCKET, Key="multipart.bin")
    s3.delete_bucket(Bucket=BUCKET)
    print(f"   removed {BUCKET}")

    print("\nALL CHECKS PASSED")


if __name__ == "__main__":
    try:
        main()
    except EndpointConnectionError as e:
        sys.exit(f"\nCONNECT FAILED - DNS/route/VirtualService problem:\n{e}")
    except ClientError as e:
        code = e.response["Error"]["Code"]
        msg = e.response["Error"].get("Message", "")
        sys.exit(f"\nS3 ERROR {code}: {msg}\n"
                 f"  SignatureDoesNotMatch / InvalidAccessKeyId -> wrong key\n"
                 f"  AccessDenied -> identity actions in the s3 config\n"
                 f"  NoSuchBucket -> create_bucket step failed")