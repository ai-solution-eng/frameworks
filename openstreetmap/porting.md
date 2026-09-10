# Porting - OSM Seed

Self-contained OpenStreetMap stack for HPE Private Cloud AI: the **osm-seed**
chart deploys the OSM website/API (`web` + `cgimap` + PostgreSQL), the Nominatim
geocoder, Overpass, the Tasking Manager, OSMCha, Taginfo and the tiler stack
(imposm, Martin, Varnish cache) — 17 default-enabled workloads plus a bundled
MinIO — behind one Istio `ezaf-gateway` endpoint at `https://osm-seed.${DOMAIN_NAME}`.
Ported in place from the upstream chart at
https://github.com/osm-seed/osm-seed (published chart repo
https://osm-seed.github.io/osm-seed-chart). Deployed via the PCAI
**Import Framework** button; `${DOMAIN_NAME}` is substituted by the platform at
import time.

## values.yaml

```yaml
ezua:
  domainName: ${DOMAIN_NAME}
  virtualService:
    endpoint: osm-seed.${DOMAIN_NAME}
    istioGateway: istio-system/ezaf-gateway
    destinationService: ""        # defaults to <release>-service-web
    destinationPort: 80
  authorizationPolicy:
    namespace: istio-system
    providerName: oauth2-proxy
    enabled: false                # set true to require platform SSO
```

- The VirtualService routes the endpoint to
  `{{ .Values.ezua.virtualService.destinationService | default "<release>-service-web" }}.{{ .Release.Namespace }}.svc.cluster.local:80`
  (the Service fronting the OSM web UI/API, containerPort 80). Point
  `destinationService`/`destinationPort` at any other component instead — e.g.
  `<release>-nominatim-api`, `<release>-overpass-api`, `<release>-tiler-varnish`.
- The AuthorizationPolicy (`action: CUSTOM`, provider `oauth2-proxy`, matching
  the endpoint host) is created in `istio-system` — the importing user needs
  RBAC there. `enabled: false` (default) serves the app anonymously, no
  default-deny; `true` gates it behind platform SSO.

### Storage

- `cloudProvider: pvc` (default) — each `*-pd.yaml` renders a standalone
  `PersistentVolumeClaim` (no PV) provisioned by the cluster's default
  StorageClass (`storageClassName` omitted unless set per component), keeping
  `helm.sh/resource-policy: keep`. The broken "unknown provider" PV branch is
  gated off; `aws`/`k3s` modes render upstream behavior unchanged.
- `s3.provider: minio` (default) deploys a **dedicated MinIO as part of the
  release** (`templates/minio/`): standalone-mode StatefulSet
  (`minio/minio:RELEASE.2025-07-23T15-54-02Z`), ClusterIP Service
  (`<release>-minio` :9000 API / :9001 console), 20Gi data PVC, and a
  bucket-init CronJob (`*/5 * * * *`, `Forbid`, idempotent
  `mc mb --ignore-existing`) — a regular chart resource, because helm hook Jobs
  are skipped by the PCAI Import path.
- `s3.minio.accessKey/secretKey` are both the server's
  `MINIO_ROOT_USER/MINIO_ROOT_PASSWORD` and consumers'
  `AWS_ACCESS_KEY_ID/SECRET_ACCESS_KEY` (single source; demo creds — rotate).
  The endpoint (`http://<release>-minio.<ns>.svc.cluster.local:9000`) is
  computed in-chart by `osm-seed.s3Endpoint`; the external `s3.minio.endpoint`
  value was removed.
- Helpers `osm-seed.s3Env` / `osm-seed.s3Creds` inject `AWS_S3_BUCKET` (s3://
  style), `AWS_S3_BUCKET_NAME`, creds and `AWS_ENDPOINT_URL`/`AWS_ENDPOINT`
  into every S3-consuming workload — **only when provider=minio**. Wired into:
  tiler-imposm, tiler-server (via its configMap, incl.
  `TILER_CACHE_FORCE_PATH_STYLE: "true"`), full-history, planet-dump,
  changesets-dump (`DUMP_CLOUD_URL` → `s3://openstreetmap/db.dump`),
  replication jobs, db backup cronjobs, taginfo processor. `provider: aws`
  renders exactly upstream behavior (zero endpoint artifacts, no MinIO).

### Corporate wall (CA bundle + proxy)

Three independent blocks, all **enabled: false** by default:

- `certificatesPolicy` — an init container (default `alpine:3.20`; use a
  corporate-baked image that carries the CA bundle) copies
  `/path/to/ca-certificates.crt` into a shared `combined-certs` emptyDir;
  every container mounts it at `/tmp/certs` and gets
  `SSL_CERT_FILE=/tmp/certs/ca-certificates.crt`.
- `proxy` / `no_proxy` — HTTP(S)_PROXY / NO_PROXY env lists. NO_PROXY covers
  in-cluster services (`.svc.cluster.local` by default, which keeps MinIO/S3
  traffic off-proxy).

Six gated helpers (`osm-seed.proxyCertsEnv`, `certsInitContainer`/
`certsInitEntry`, `certsVolumeMountsBlock/Entry`, `certsVolumesBlock/Entry`)
wire this uniformly into every pod-bearing template (all containers + a
`copy-ca-certificates` init container per pod). Air-gapped clusters: mirror
images and override `*.image.*` — defaults pull anonymously from Docker Hub
and public GHCR.

### Defaults

- Default-enabled ("everything web-facing"): `db`, `memcached`, `web`, `cgimap`,
  `nominatimApi`, `nominatimUI`, `overpassApi`, `taginfoWeb`, `osmchaApi`,
  `osmchaDb`, `tmApi`, `tmDb`, `tilerDb`, `tilerImposm`, `tilerServer`,
  `tilerVarnish`, `tilerServerMartin`, `tilerCache`, `level0`. Batch/jobs stay
  disabled; ingresses, cert-manager issuer, `osmx-adiff-builder`,
  `tiler-monitor-*` and `planetStats` remain opt-in.
- Image defaults are pinned and verified anonymous-pullable: Docker Hub
  `developmentseed/osmseed-db|web|nominatim|overpass-api|osmcha-db|osmcha-web|tasking-manager-api|tiler-db|tiler-imposm|tiler-server`
  @ `1.0.0-dev.hb293d54`, plus `osmseed-cgimap:1.0.0-rel.hf7a3340` (the GHCR
  dev tag is missing its binary), `postgres:11` (tm-db — see Notes), `varnish:7.6`;
  GHCR `ghcr.io/osm-seed/web|taginfo-web|level0`,
  `ghcr.io/openhistoricalmap/tiler-server-martin|tiler-cache`,
  `ghcr.io/osmcha/osmcha-django`, `ghcr.io/openhistoricalmap/nominatim-ui`.
- Extract/replication URLs default to the Monaco extract
  (`https://data.bbbike.org/osm/pbf/region/europe/monaco.osm.pbf` + osm-fr
  minute replication) via `overpassApi.env.OVERPASS_PLANET_URL`/`OVERPASS_DIFF_URL`,
  `nominatimApi.env.PBF_URL`/`REPLICATION_URL` and
  `tilerImposm.env.TILER_IMPORT_PBF_URL`/`REPLICATION_URL` — swap per region by
  values (see Sizing).
- tiler-server runs self-contained via its StatefulSet with
  `TILER_CACHE_TYPE: file` (+50Gi PVC); set back to `s3` (with S3 creds) for
  the Deployment/S3-cache variant.
- S3-access ServiceAccounts (`web`, `tilerImposm`, `tilerServer`) are disabled
  by default — the referenced SAs are created outside this chart and don't
  exist on a fresh PCAI namespace.
- `web.nodeAffinity.enabled: false` (upstream's default requires
  `nodegroup_type=web` node labels that don't exist on PCAI → pod Pending).

## Templates added and modified

- `templates/virtualservice.yaml` — EzUA gateway → `<release>-service-web:80`.
- `templates/authorizationPolicy.yaml` — gated on
  `ezua.authorizationPolicy.enabled`.
- `_hpe-ezua` labels helper — `hpe-ezua/type: vendor-service`,
  `hpe-ezua/app: osm-seed`, applied **natively** to all workload/service
  templates (metadata.labels + pod-template labels, incl. CronJob
  `jobTemplate.spec.template.metadata`). Native over Kyverno: the templates are
  ours to edit and native labels work on any PCAI cluster without a Kyverno
  dependency. `selector.matchLabels` deliberately untouched, so upgrades of
  existing releases stay safe.
- `templates/minio/` — bundled MinIO (see values section); the MinIO pod
  carries the same corporate-wall wiring as every other pod (the bucket-init
  CronJob deliberately gets no proxy env).
- `templates/NOTES.txt` — prints the EzUA gateway URL.
- Carried upstream fixes: `db.env.PGDATA` (missing → added), tiler-server HPA
  autoscaling values (missing → added, disabled by default), nominatimApi
  startup/liveness probes (missing → added; startup allows ~24h for the
  import), batch components got real image defaults (`dbBackupRestore.image`
  rendered `image: :` when enabled).
- `templates/overpass-api`: all 8 env keys render into `env` (an earlier edit
  re-nested 4 keys under `livenessProbe`, breaking fresh-volume installs).
- nominatim: a `<release>-nominatim-pgconf` ConfigMap (`ssl = off`) is mounted
  at `/etc/postgresql/16/main/conf.d/nominatim.conf` via **subPath** — platform
  CA injection into `/etc/ssl/certs` (read-only) hides the image's snakeoil
  cert its internal PostgreSQL requires, and a plain directory mount would mask
  the image's own `conf.d` (breaking the import tuning); the single-file subPath
  mount adds the override next to the image's files.
- tm-db: a `tm-db-initdb` ConfigMap (`CREATE EXTENSION IF NOT EXISTS postgis;`)
  mounted at `/docker-entrypoint-initdb.d/` (runs on first init only).

## Sizing

Monaco demo by default; a planet import is a pure values change:

| Knob | Monaco (default) | Full planet (~85GB PBF) |
|---|---|---|
| `overpassApi.persistenceDisk.size` | 50Gi | **800Gi–1TB** (import 3–7 days) |
| `overpassApi.livenessProbe.initialDelaySeconds` | 14400 (4h) | **604800** (7 days) — else kubelet kills mid-import |
| `nominatimApi.persistenceDisk.size` | 100Gi | **500–600Gi** (import 24–48h) |
| `nominatimApi.startupProbe.failureThreshold` | 1440 (≈24h budget) | raise for >24h imports (e.g. 4320 ≈ 72h) |
| `tilerDb.persistenceDisk.size` | 20Gi | **300–500Gi** (imposm import 10–24h) |
| `tilerImposm.livenessProbe.initialDelaySeconds` | 14400 | raise similarly |
| `db.persistenceDisk.size` | 50Gi | **1.5–2.5TB** (optional: full-planet API/editing DB via osmosis) |
| `*.resources.enabled` | false (BestEffort) | **true + guaranteed requests** for the big four (OOM protection) |
| extract URLs | BBBike Monaco extract | `https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf` |

Operational notes: run the big imports **sequentially** on single-worker
clusters (each is RAM/IO heavy); DB imports prefer block storage (e.g.
`gl4f-block-csi`) over filesystem; total disk ~1.5TB (viewer tier) to ~3.5TB+
(with the API DB); planet download ~85GB once through the proxy. A continent
extract (e.g. Europe ~30GB) is the middle ground at ~1/10th cost. When enabling
`*.resources`, always set `limits.cpu` — pods without a cpu limit fail EzLicense
scheduling.

⚠️ **Nominatim storage quirk (required for planet imports)**: the PVC is
mounted at `/var/lib/postgresql/14/main` but the image's internal PostgreSQL is
v16 (`/var/lib/postgresql/16/main`) — the DB is container-local and re-imports
on every pod restart (invisible at Monaco scale ≈1 min). For a planet import
set `nominatimApi.persistenceDisk.mountPath: /var/lib/postgresql/16/main` so
the DB lands on the PVC.

## Notes

- **Geofabrik blocks datacenter IPs** (verified: extract pages exist publicly,
  clusters get a genuine 404) → PBF URLs use the BBBike region mirror and
  replication diffs use `https://download.openstreetmap.fr/replication/...`;
  plain `http://` URLs also 404 from inside clusters — always `https://`.
- **cgimap**: the chart overrides the container `command` with an inline replica
  of `start.sh` passing `--dbname/--host/--username/--password` explicitly (the
  released image relies on `CGIMAP_*` env the pinned binary doesn't map), runs
  in the foreground with `--instances=10` (`--daemon` forks → PID 1 exits →
  `Completed` restart loop), and probes `tcpSocket: 8000` (the image ships no
  liveness script; exec probes failed at `/app/liveness.sh` and `/liveness.sh`).
  Revert to the image entrypoint once images are rebuilt with the fixed
  `images/cgimap/start.sh`. (web/tiler-imposm keep `./liveness.sh`.)
- **tm-db**: TM's migration needs PostGIS — image is `postgis/postgis:11-3.3`
  (vanilla `postgres:11` lacks the extension) plus the initdb ConfigMap above;
  the existing PVC had to be deleted once so the fresh init picked up the
  extension. `TM_DB` scheme is plain `postgresql://` — the pinned image has no
  asyncpg driver, so `postgresql+asyncpg://` fails.
- **tasking-manager init** runs `cd /usr/src/app && python3 manage.py db upgrade` (Flask-Migrate); raw `alembic` fails with "Working outside of application context".
- **web credentials**: `web.env.RAILS_MASTER_KEY` / `RAILS_CREDENTIALS_YML_ENC`
  must be **empty strings** so the image's baked-in credentials survive —
  non-empty placeholders like `none` overwrite them →
  `ActiveSupport::MessageEncryptor::InvalidMessage` at boot, Passenger refuses
  to spawn, gateway 500. First boot runs `rails db:migrate` and creates the
  full OSM API schema; for production supply a real key + matching
  encrypted-credentials pair.
- **osmcha-api** probes `tcpSocket: 5000` (this build has no
  `/api/v1/health` route; the 404 killed gunicorn every ~90s).
- **MinIO**: the `minio/minio` image's `ENTRYPOINT` is a wrapper script — the
  server flags belong in `args:`, not `command:` (overriding `command:` with
  the binary crashes with `exec: "server": executable file not found in $PATH`).
- **tiler-cache** requires AWS SQS — MinIO cannot serve it, so it ships
  `enabled: false`. osmcha fetch/process cronjobs default off (they need the
  changeset-replication pipeline's YAML state).
- **AWS CLI v1** does not read `AWS_ENDPOINT_URL` — all CLI-based image scripts
  got a no-op-unless-set `--endpoint-url $AWS_ENDPOINT_URL` pattern, and
  `CLOUDPROVIDER==aws` gates are relaxed with `|| [ -n "$AWS_ENDPOINT_URL" ]`.
  Needs a chartpress image rebuild to take effect (batch S3 jobs are disabled
  until then).
- **Upgrade drift**: re-upgrading with an older tgz reverts value fixes —
  always upgrade with the latest package (the Rails credentials fix was lost
  this way once). Hot-fix without upgrade:
  `kubectl set env deployment/osm-seed-web RAILS_MASTER_KEY="" RAILS_CREDENTIALS_YML_ENC="" -n osm-seed`.
- **Startup ordering** is the main false alarm: postgres init → dependent
  init-migrations crashloop until DBs are ready; CrashLoopBackOff resets after
  pod deletion or backoff expiry.

# HPE notes

- Upstream chart: https://github.com/osm-seed/osm-seed (published chart
  https://osm-seed.github.io/osm-seed-chart). `Chart.yaml` keeps
  `apiVersion: v1` (upstream chartpress CI compatibility) and sets the version
  explicitly (upstream fills it at publish time).
- Packaged as `osm-seed-<version>.tgz` at the repo root and imported via the
  PCAI **Import Framework** button. Bump the version in `Chart.yaml` for every
  re-import — PCAI rejects re-uploading the same application name + version.
- Verified with `helm lint` and `helm template` (default + all-toggles-on
  renders, 55 resources: 1 VirtualService, 1 AuthorizationPolicy, 10
  Deployments, 8 StatefulSets, 2 CronJobs, 19 Services, 8 PVCs, 3
  PriorityClasses, 6 ConfigMaps, 1 HPA) plus rendered-coverage audits (labels,
  certs, proxy, S3 endpoints — zero-miss policy when enabled, zero artifacts
  when disabled). Regression: `cloudProvider=aws` still renders PV+PVC pairs,
  `k3s` still renders local-path PVCs.
- Verified on installs across dc15, gen2, ld7r104 and a devday system (fresh
  volumes, PCAI Import path). Fresh-volume installs and non-helm deployment
  paths surface failure classes that upgrade-style installs mask — hence the
  render audits on every change.
- Values to override at import time: PVC sizes and
  `persistenceDisk.storageClassName`; demo credentials (`db.env.POSTGRES_PASSWORD`,
  `tmDb`/`tmApi`, `osmchaApi.env` OAuth/Django secrets, `web.env`
  OAUTH/MAILER/RAILS_*); exposure (`ezua.virtualService.destinationService`/
  `destinationPort`, `ezua.authorizationPolicy.enabled: true` for SSO); images
  for restricted registries. Resource footprint is heavy by design — scale down
  or disable components via `*.enabled`.
- Serving path is fully self-contained: all workloads and data on PVCs, bundled
  MinIO, ezaf-gateway + oauth2-proxy. Internet is used only for one-time data
  imports, optional replication diffs (osm-fr), image pulls (node-cached), and
  config-level integrations: website user login (`web.env.OAUTH_CLIENT_ID`/
  `OAUTH_KEY` or point the site at its own API via `web.env.OSM_SERVER_URL`),
  email (`web.env.MAILER_*`, `tmApi.env.TM_SMTP_*`), and level0 editor writes
  (`level0.env.OSM_API_URL` → `http://osm-seed-service-web/api/0.6/` +
  `OSM_WEBSITE_URL` — needs a matching local OAuth2 app for saving edits).
