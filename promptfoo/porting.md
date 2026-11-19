# Porting the promptfoo Helm chart to HPE Private Cloud AI (AI Essentials)

This document records how the upstream promptfoo Helm chart was converted into a chart that
can be imported as a framework tile in HPE AI Essentials Software (1.12.x) on Private Cloud AI
(PCAI). It explains every change, why it was made, how to build and import the chart, and how
to troubleshoot an import that does not come up.

| | |
|---|---|
| Upstream repo | https://github.com/promptfoo/promptfoo |
| Upstream chart path | `helm/chart/promptfoo` |
| Upstream commit used | `9a7187a` (2026-11-16) |
| Upstream chart / app version | `0.1.0` / `0.54.1` (image tag pinned to a non-existent `v1.0.0`) |
| Ported chart / app version | `0.2.0` / `0.125.1` |
| Integration method | Manual (VirtualService + AuthorizationPolicy templates + `hpe-ezua` labels) |
| Reference | HPE AI Essentials Software 1.12.x – *Preparing the Framework Helm Chart* |

---

## 1. What promptfoo is and how it runs

promptfoo is an LLM evaluation and red-teaming tool. The container image
(`ghcr.io/promptfoo/promptfoo`) runs a single Express server that serves both the web UI and
the API on port **3000**:

- Runs as the non-root `promptfoo` user.
- Stores everything (SQLite `promptfoo.db`, blobs, media) in `/home/promptfoo/.promptfoo`.
- Exposes `GET /health` for health checks (used by the image's own `HEALTHCHECK`).
- Keeps eval jobs in memory, so it **cannot run more than one replica** (upstream docs warn of
  "Job not found" errors with multiple pods sharing one SQLite file).

That shapes the port: one replica, one ReadWriteOnce volume, one HTTP service, no GPU.

---

## 2. Why the manual method and not AutoHelm

The HPE doc recommends AutoHelm (`ezua.autoHelm: true`) for simple charts, but notes it works
best with **a single service on port 80**. promptfoo's service listens on **3000**, so the
manual method was used: the chart ships its own VirtualService and AuthorizationPolicy
templates and applies the `hpe-ezua` labels itself. This also keeps the chart's behaviour
explicit and reviewable.

---

## 3. Summary of changes

| # | File | Change | Required by PCAI? |
|---|---|---|---|
| 1 | `templates/ingress.yaml` | **Deleted** | Yes – PCAI exposes apps via Istio, not Ingress |
| 2 | `templates/ezua/virtualService.yaml` | **New** Istio VirtualService | Yes |
| 3 | `templates/ezua/authpolicy.yaml` | **New** Istio AuthorizationPolicy (SSO) | Yes |
| 4 | `templates/_hpe-ezua.tpl` | **New** `hpe-ezua.labels` helper | Yes |
| 5 | `templates/deployment.yaml` | `hpe-ezua` labels on Deployment + pod template | Yes |
| 6 | `values.yaml` | New `ezua` section with `${DOMAIN_NAME}` placeholder | Yes |
| 7 | `templates/deployment.yaml` | Share URLs point at the PCAI endpoint, not localhost | Functional fix |
| 8 | `templates/deployment.yaml` + `values.yaml` | `strategy: Recreate` | Functional fix |
| 9 | `templates/deployment.yaml` + `values.yaml` | New `extraEnv` passthrough | Convenience |
| 10 | `values.yaml` | Image tag falls back to `appVersion`; pull-secret placeholder removed | Functional fix |
| 11 | `values.yaml` | `fsGroup: 1000` | Functional fix |
| 12 | `values.yaml` + `templates/pvc.yaml` | Default StorageClass, 5Gi | Functional fix |
| 13 | `values.yaml` | Probes on `/health`, with delays | Functional fix |
| 14 | `values.yaml` | Larger CPU / memory | Functional fix |
| 15 | `Chart.yaml` | Description, chart version, appVersion | Housekeeping |

Unchanged: `_helpers.tpl`, `service.yaml`, `serviceaccount.yaml`, `hpa.yaml`,
`tests/test-connection.yaml`, `.helmignore`.

---

## 4. Final layout

Follows the [ai-solution-eng/frameworks](https://github.com/ai-solution-eng/frameworks)
repo convention. This file lives **next to** the chart, not inside it, so it is never packaged
into the `.tar.gz` that gets uploaded to AI Essentials.

```
promptfoo/
├── logo.png                            # tile icon for the import screen
├── porting.md                          # this file (outside the chart)
├── promptfoo-0.2.0.tar.gz              # packaged chart, ready to import
└── promptfoo/                          # chart source
    ├── .helmignore
    ├── Chart.yaml                      # modified
    ├── values.yaml                     # modified
    └── templates/
        ├── _helpers.tpl
        ├── _hpe-ezua.tpl               # NEW
        ├── deployment.yaml             # modified
        ├── hpa.yaml
        ├── pvc.yaml                    # modified
        ├── service.yaml
        ├── serviceaccount.yaml
        ├── ezua/                       # NEW
        │   ├── authpolicy.yaml
        │   └── virtualService.yaml
        └── tests/
            └── test-connection.yaml
```

`templates/ingress.yaml` is gone.

---

## 5. Changes in detail

### 5.1 Removed `templates/ingress.yaml`

Upstream shipped an always-on Ingress (no `enabled` flag) hardcoded to Traefik and a
cert-manager issuer that only exists in promptfoo's own environment:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-cloudflare
spec:
  ingressClassName: traefik
  rules:
  - host: {{ $.Values.domainName }}
```

On PCAI there is no Traefik class and no such issuer; external access goes through the Istio
ingress gateway `istio-system/ezaf-gateway`, which handles the platform's TLS for app
hostnames under `${DOMAIN_NAME}`. Keeping the file would create a dead Ingress at best. Because it could not
be switched off from values, it was deleted, along with the `domainName` value it used.

### 5.2 New `templates/ezua/virtualService.yaml`

Taken from the HPE template, pointed at promptfoo's service:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: {{ printf "%s-%s-virtual-service" .Release.Name .Chart.Name }}
  labels:
    {{- include "promptfoo.labels" . | nindent 4 }}
spec:
  gateways:
    - {{ .Values.ezua.virtualService.istioGateway | required "..." }}
  hosts:
    - {{ .Values.ezua.virtualService.endpoint | required "..." }}
  http:
    - match:
        - uri:
            prefix: /
      rewrite:
        uri: /
      route:
        - destination:
            host: {{ include "promptfoo.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
            port:
              number: {{ .Values.service.port }}     # 3000
```

- The destination host uses the same `promptfoo.fullname` helper as `service.yaml`, so the two
  always agree, whatever the release name.
- `required` makes `helm template` fail loudly if the `ezua` values are missing, instead of
  rendering a broken VirtualService.
- promptfoo serves its UI at `/` (no base path), so the `/` → `/` rewrite is a no-op that keeps
  the HPE template shape.

### 5.3 New `templates/ezua/authpolicy.yaml`

Verbatim HPE template. It creates a `CUSTOM` AuthorizationPolicy **in `istio-system`** that
sends every request for the promptfoo host through the platform's `oauth2-proxy`
ext-authz provider, so users must be signed in to PCAI (Keycloak) to reach the tile.

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: {{ printf "%s-%s-auth-policy" .Release.Name .Chart.Name }}
  namespace: {{ .Values.ezua.authorizationPolicy.namespace }}   # istio-system
spec:
  action: CUSTOM
  provider:
    name: {{ .Values.ezua.authorizationPolicy.providerName }}   # oauth2-proxy
  rules:
    - to:
        - operation:
            hosts:
            - {{ .Values.ezua.virtualService.endpoint }}
  selector:
    matchLabels:
      istio: ingressgateway
```

**Keycloak redirect URL: not needed.** promptfoo has no login of its own and does not speak
OAuth2, so the gateway-level SSO above is the whole story. The optional Keycloak
`/oauth2/callback` redirect step in the HPE doc applies only to apps that do their own OAuth2
flow.

### 5.4 New `templates/_hpe-ezua.tpl`

Verbatim from the HPE doc:

```yaml
{{- define "hpe-ezua.labels" -}}
hpe-ezua/app: {{ .Release.Name }}
hpe-ezua/type: vendor-service
{{- end }}
```

- `hpe-ezua/app` – the EzAppConfig controller finds the app's pods with
  `hpe-ezua/app=<release>` to compute tile health.
- `hpe-ezua/type: vendor-service` – classifies the pods as an imported framework and enables
  resource-usage collection.

Without **both** labels the tile shows health `Unknown`.

`hpe-ezua/component` and `hpe-ezua/resource-type` are not set: promptfoo is CPU-only and has a
single component, and the doc requires those labels (plus a PriorityClass) only for GPU
workloads. If your platform's Kyverno policies demand a component label on every framework
pod, add `hpe-ezua/component: promptfoo` to the helper.

### 5.5 `hpe-ezua` labels in `templates/deployment.yaml`

```diff
 metadata:
   labels:
     {{- include "promptfoo.labels" . | nindent 4 }}
+    {{- include "hpe-ezua.labels" . | nindent 4 }}
 ...
   template:
     metadata:
       labels:
         {{- include "promptfoo.labels" . | nindent 8 }}
+        {{- include "hpe-ezua.labels" . | nindent 8 }}
```

The labels go on the Deployment and on the pod template (the pod labels are what the
controller actually queries). They are deliberately **not** added to `selectorLabels`
(the doc's alternative approach): a Deployment's selector is immutable, so changing it would
break `helm upgrade` from any earlier install, and the selector does not need them.

### 5.6 New `ezua` section in `values.yaml`

```yaml
ezua:
  virtualService:
    endpoint: 'promptfoo.${DOMAIN_NAME}'
    istioGateway: 'istio-system/ezaf-gateway'
  authorizationPolicy:
    namespace: 'istio-system'
    providerName: 'oauth2-proxy'
    matchLabels:
      istio: 'ingressgateway'
```

`${DOMAIN_NAME}` is substituted by AI Essentials at import time, and only inside
`EzAppConfig.Spec.Values`. If you install with plain `helm install`, you must pass the real
host yourself (`--set ezua.virtualService.endpoint=promptfoo.<domain>`).

### 5.7 Share URLs point at the PCAI endpoint

```diff
             - name: PROMPTFOO_REMOTE_API_BASE_URL
-              value: http://localhost:3000
+              value: {{ printf "https://%s" .Values.ezua.virtualService.endpoint | quote }}
             - name: PROMPTFOO_REMOTE_APP_BASE_URL
-              value: http://localhost:3000
+              value: {{ printf "https://%s" .Values.ezua.virtualService.endpoint | quote }}
```

promptfoo uses these to build share links. With `localhost` every link it generated pointed
at the user's own machine. They now resolve to e.g. `https://promptfoo.<domain>`.

### 5.8 `strategy: Recreate`

```yaml
# deployment.yaml
  {{- with .Values.strategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}

# values.yaml
strategy:
  type: Recreate
```

Not a PCAI requirement. The default `RollingUpdate` starts the new pod before stopping the old
one. With a ReadWriteOnce PVC that either hangs the rollout with a Multi-Attach error (new pod
on another node) or briefly runs two processes on one SQLite file (same node). `Recreate`
stops the old pod first, at the cost of a few seconds of downtime per upgrade (unavoidable with
one replica anyway). Delete `strategy` from values to get the Kubernetes default back.

### 5.9 `extraEnv` passthrough

```yaml
            {{- with .Values.extraEnv }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
```

Lets you add provider credentials or point promptfoo at in-cluster models without editing
templates, e.g. LiteLLM or an MLIS OpenAI-compatible endpoint:

```yaml
extraEnv:
  - name: OPENAI_BASE_URL
    value: http://litellm.litellm.svc.cluster.local:4000/v1
  - name: OPENAI_API_KEY
    valueFrom:
      secretKeyRef:
        name: promptfoo-provider-keys
        key: OPENAI_API_KEY
```

### 5.10 Image tag and pull secret

```diff
 image:
   repository: ghcr.io/promptfoo/promptfoo
-  tag: v1.0.0
+  tag: ''
-imagePullSecrets:
-  - name: <yourcred>
+imagePullSecrets: []
```

- Upstream pinned `v1.0.0`, but promptfoo publishes semver tags **without** a `v` prefix
  (`0.125.1`, `0.125`, `latest`). With an empty tag the Deployment uses
  `.Chart.AppVersion` → `ghcr.io/promptfoo/promptfoo:0.125.1`.
- The `<yourcred>` placeholder referenced a secret that does not exist. The image is public, so
  no secret is needed.

### 5.11 `fsGroup: 1000`

```yaml
podSecurityContext:
  fsGroup: 1000
```

The image runs as the non-root `promptfoo` user. Many CSI volumes mount root-owned, so promptfoo
could not create `promptfoo.db`. `fsGroup` makes the kubelet set group ownership on the volume
so it is writable.

> The image creates `promptfoo` with Alpine's `adduser -S`, so its own UID/GID is a system ID,
> not 1000. That is fine: Kubernetes adds `fsGroup` as a supplementary group to the container
> process, so the volume is writable whatever the user's primary GID. If the pod logs still show
> `EACCES` / `SQLITE_CANTOPEN` on `/home/promptfoo/.promptfoo`, your CSI driver probably ignores
> `fsGroup`; check with `kubectl exec -n promptfoo deploy/promptfoo -- id` and
> `ls -ln /home/promptfoo/.promptfoo`.

### 5.12 Storage

```diff
 persistentVolumesClaims:
   - name: promptfoo
-    size: 1Gi
+    size: 5Gi
     accessModes:
       - ReadWriteOnce
-    storageClassName: default
+    storageClassName: ''
```

and in `pvc.yaml`:

```diff
+  {{- if .storageClassName }}
   storageClassName: {{ .storageClassName }}
+  {{- end }}
```

Upstream requested a StorageClass literally named `default`, which PCAI clusters do not have,
so the PVC would stay `Pending` forever. Now the field is omitted when empty and the cluster's
default StorageClass is used. 5Gi leaves room for eval history and externalized media blobs.

> Note: the upstream key is spelled `persistentVolumesClaims` (sic) and the chart's templates
> use that spelling. Upstream's docs say `persistentVolumeClaims`; use the chart's spelling in
> override files.

### 5.13 Probes

```diff
 livenessProbe:
   httpGet:
-    path: /
+    path: /health
     port: http
+  initialDelaySeconds: 15
+  periodSeconds: 20
 readinessProbe:
   httpGet:
-    path: /
+    path: /health
     port: http
+  initialDelaySeconds: 5
+  periodSeconds: 10
```

`/health` is the endpoint the server and the image `HEALTHCHECK` use. Probing `/` fetches the
whole UI bundle on every probe, and the delays avoid restarts while Node starts up.

### 5.14 Resources

```diff
 resources:
   limits:
-    cpu: 100m
-    memory: 128Mi
+    cpu: '1'
+    memory: 2Gi
   requests:
-    cpu: 100m
-    memory: 128Mi
+    cpu: 250m
+    memory: 512Mi
```

128Mi is too little for a Node.js server that holds eval jobs in memory, and it gets OOM-killed
on real evals. The new values are a sizing estimate, not an upstream recommendation; raise the
limit for large red-team runs.

### 5.15 `Chart.yaml`

- `description` → `Promptfoo - LLM evals and red teaming (HPE Private Cloud AI / AI Essentials framework chart)`
- `version` `0.1.0` → `0.2.0` (bump it on every change you re-import: ChartMuseum will not
  overwrite an existing version)
- `appVersion` `0.54.1` → `0.125.1`

---

## 6. Rendered output (what gets created)

With `DOMAIN_NAME=pcai.example.local`, release `promptfoo`, namespace `promptfoo`:

| Kind | Name | Namespace |
|---|---|---|
| Deployment | `promptfoo` | promptfoo |
| Service (ClusterIP :3000) | `promptfoo` | promptfoo |
| ServiceAccount | `promptfoo` | promptfoo |
| PersistentVolumeClaim (5Gi RWO) | `promptfoo` | promptfoo |
| VirtualService | `promptfoo-promptfoo-virtual-service` | promptfoo |
| AuthorizationPolicy | `promptfoo-promptfoo-auth-policy` | **istio-system** |
| Pod (helm test hook only) | `promptfoo-test-connection` | promptfoo |

Key parts of the rendered Deployment:

```yaml
metadata:
  labels:
    app.kubernetes.io/name: promptfoo
    app.kubernetes.io/instance: promptfoo
    hpe-ezua/app: promptfoo
    hpe-ezua/type: vendor-service
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        hpe-ezua/app: promptfoo
        hpe-ezua/type: vendor-service
    spec:
      securityContext:
        fsGroup: 1000
      containers:
        - name: promptfoo
          image: "ghcr.io/promptfoo/promptfoo:0.125.1"
          env:
            - name: PROMPTFOO_REMOTE_API_BASE_URL
              value: "https://promptfoo.pcai.example.local"
            - name: PROMPTFOO_REMOTE_APP_BASE_URL
              value: "https://promptfoo.pcai.example.local"
          volumeMounts:
            - mountPath: /home/promptfoo/.promptfoo
              name: config
```

---

## 7. Build, lint and package

From the directory that contains the `promptfoo/` chart folder:

```bash
# Lint (passes as-is; ${DOMAIN_NAME} is just a string to Helm)
helm lint ./promptfoo
helm lint ./promptfoo --set ezua.virtualService.endpoint=promptfoo.<your-domain>

# Inspect the rendered manifests
helm template promptfoo ./promptfoo -n promptfoo \
  --set ezua.virtualService.endpoint=promptfoo.<your-domain>

# Package -> promptfoo-0.2.0.tgz, then rename to the repo convention
helm package ./promptfoo
mv promptfoo-0.2.0.tgz promptfoo-0.2.0.tar.gz
```

Sanity-check the package before uploading it. All three must return something, and the
`ingress` grep must return nothing:

```bash
tar -tzf promptfoo-0.2.0.tar.gz | grep -E 'ezua/|_hpe-ezua.tpl'
tar -tzf promptfoo-0.2.0.tar.gz | grep ingress            # expect no output
tar -xzOf promptfoo-0.2.0.tar.gz promptfoo/Chart.yaml  | grep description
tar -xzOf promptfoo-0.2.0.tar.gz promptfoo/values.yaml | grep -A3 '^ezua'
```

If `description` still says `A Helm chart for Kubernetes`, you are packaging an upstream or
partly edited copy.

---

### Validation status

The chart was checked by rendering every template with the values above (with
`${DOMAIN_NAME}` replaced) and parsing the result as YAML: all seven objects in section 6
render correctly. `helm lint` and `helm template` were **not** run during the port (no helm
binary was available), so run the commands above once before the first import.

## 8. Importing into AI Essentials

1. In the AI Essentials UI open **Tools & Frameworks** and choose **Import Framework** (see the
   HPE doc *Importing Frameworks Using UI* for your release's exact screens).
2. Name: `promptfoo`, and add a description.
3. Upload `promptfoo-0.2.0.tar.gz`, and `logo.png` as the tile icon.
4. Namespace: `promptfoo`.
5. Review the values. Do **not** enable *Apply Helm Chart Config* (AutoHelm); the chart already
   contains its own templates and labels.
6. Submit. The tile appears; **Open** should go to `https://promptfoo.<your-domain>` after the
   pod is Ready and SSO sign-in completes.

### Air-gapped clusters

Mirror the image into your registry (e.g. Harbor) and override the repository at import:

```bash
skopeo copy docker://ghcr.io/promptfoo/promptfoo:0.125.1 \
            docker://<harbor>/<project>/promptfoo:0.125.1
```

```yaml
image:
  repository: <harbor>/<project>/promptfoo
imagePullSecrets:
  - name: <harbor-pull-secret>    # only if the project is private
```

The `${AIRGAP_REGISTRY}` placeholder can also be used, e.g.
`repository: '${AIRGAP_REGISTRY}/promptfoo/promptfoo'`.

---

## 11. Known limitations

- **Single replica only.** SQLite plus an in-memory job queue; do not enable `autoscaling` or
  raise `replicaCount`.
- **CLI sharing from outside the cluster hits SSO.** `promptfoo share` against
  `https://promptfoo.<domain>` gets the oauth2-proxy login redirect. From notebooks or pods
  inside the cluster, point the CLI at the service directly:
  ```bash
  export PROMPTFOO_REMOTE_API_BASE_URL=http://promptfoo.promptfoo.svc.cluster.local:3000
  export PROMPTFOO_REMOTE_APP_BASE_URL=https://promptfoo.<domain>
  ```
- **No per-user separation.** Everyone who passes SSO sees the same eval history.
- **Self-hosted mode is labelled "not recommended for production"** by the promptfoo project.
- **EzLicense CPU limits.** PCAI needs `resources.limits.cpu` on every pod it schedules. The
  promptfoo pod has one; the `helm test` pod does not, but it only runs on `helm test`, never
  during the import.
- `helm test` uses the `busybox` image; mirror it as well on air-gapped clusters, or skip the
  test.
