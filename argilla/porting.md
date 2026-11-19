# Porting Argilla to HPE Private Cloud AI (PCAI)

This document explains, in plain language, how the open-source Argilla Helm chart was turned into
a framework that can be imported into HPE Private Cloud AI (PCAI, also called AI Essentials). It
explains what we changed and why. No prior Kubernetes knowledge is assumed; a short glossary is
at the end.

---

## 1. What is Argilla?

[Argilla](https://github.com/argilla-io/argilla) is an open-source web app (now part of Hugging
Face) for **building and improving AI datasets with humans in the loop**.

AI teams use it to:

- **Label data:** domain experts tag text, classify documents or mark entities, for example.
- **Review model output:** people rate or correct answers from an LLM, building feedback and
  preference data for fine-tuning.
- **Evaluate models:** people score responses so you know whether a model is good enough.
- **Curate datasets:** filter, search and clean records before training.

It has two sides:

- A **web UI** where non-programmers (doctors, lawyers, support agents...) do the labeling.
- A **Python SDK** that engineers use from notebooks to push records in and pull the finished
  dataset out.

## 2. Why run Argilla on PCAI?

- **The data stays private.** Labeling often involves sensitive data such as customer tickets,
  contracts or medical notes. On PCAI it never leaves the customer's own infrastructure.
- **It sits next to the models.** Models served on PCAI (MLIS / KServe) can generate outputs that
  people then review in Argilla. The reviewed data goes straight back into fine-tuning or
  evaluation on the same platform.
- **One login for everyone.** Users sign in with their existing PCAI (Keycloak) account. Nobody
  needs a separate password for Argilla.
- **One-click tile.** Once imported, Argilla appears as a tile in the PCAI UI like any other tool.
- **Works with PCAI notebooks.** Engineers use the Argilla SDK from their PCAI notebook and talk to
  Argilla over the internal cluster network.

---

## 3. Where the chart comes from

| | |
|---|---|
| Upstream project | <https://github.com/argilla-io/argilla> |
| Upstream example chart | `examples/deployments/k8s/argilla-chart` |
| Layout we copied | `examples/deployments/docker/docker-compose.yaml` (Argilla's own recommended setup) |
| Argilla version | `v2.8.0` (Docker image `argilla/argilla-server:v2.8.0`) |
| Chart version | `2.8.0` (kept equal to the Argilla version) |
| PCAI guide followed | *Preparing the Framework Helm Chart*, AI Essentials 1.11.x |

**What's a Helm chart?** A package of Kubernetes configuration files with settings you can fill
in. PCAI imports frameworks as Helm charts.

---

## 4. What Argilla needs to run

Argilla isn't one program. It needs five pieces working together:

| Piece | What it does | Everyday analogy |
|---|---|---|
| **Argilla server** | Serves the web UI and the API | The shop front |
| **Argilla worker** | Runs slow background jobs (imports, bulk updates) | The back office |
| **PostgreSQL** | Stores users, workspaces, datasets and annotations | The filing cabinet |
| **Elasticsearch** | Makes records searchable and filterable in the UI | The index at the back of a book |
| **Redis** | A to-do queue: the server puts jobs in, the worker picks them up | The order ticket rail in a kitchen |

Our chart installs all five, and lets you point at existing ones instead (an external Postgres,
for example).

---

## 5. What we changed from the upstream chart, and why

The upstream chart is a *demo* meant for a laptop cluster (minikube). It doesn't work on PCAI as
it is. Each change below says what upstream did, why that doesn't fit PCAI, and what we did.

### 5.1 How users reach Argilla

- **Upstream:** uses an nginx **Ingress** with the made-up address `argilla.local`.
- **Why it doesn't fit:** PCAI doesn't use nginx. Every PCAI app is reached through a shared
  **Istio gateway** and protected by PCAI's single sign-on.
- **What we did:** added the two objects PCAI expects:
  - a **VirtualService**: "send `argilla.<your-domain>` to the Argilla server"
  - an **AuthorizationPolicy**: "only let logged-in PCAI users through", using the `oauth2-proxy`
    provider like every other tile

> **Important:** the AuthorizationPolicy's provider must stay `oauth2-proxy`. The gateway is shared
> by all PCAI apps, and Istio allows only one login provider per gateway. A different provider here
> would block access to **every** PCAI app. The chart refuses to install with any other value.

### 5.2 PCAI labels

- **Upstream:** has no PCAI labels.
- **Why it doesn't fit:** PCAI finds an app's pods by special labels so it can show health on the
  tile, apply its policies and track resource use. Without them the tile shows health as *Unknown*.
- **What we did:** every pod gets three labels:
  - `hpe-ezua/app: <release name>`: which app it belongs to
  - `hpe-ezua/type: vendor-service`: "this is an imported framework"
  - `hpe-ezua/component: server | worker | postgresql | elasticsearch | redis`: which part it is

### 5.3 Where Argilla keeps its data: the "SQLite on a shared disk" problem

This is the change that's easiest to misunderstand, so here it is step by step.

- **What upstream did:** it didn't run a real database. It used **SQLite**, which is a database
  stored as **a single file** on a disk. The server and the worker both read and write that same
  file, so both had to mount the same disk.
- **Why that breaks:**
  1. In Kubernetes a disk is usually **ReadWriteOnce (RWO)**: it can be plugged into **only one
     machine (node) at a time**, like a USB stick.
  2. The server and the worker are two separate pods, and Kubernetes can place them on **different
     machines**.
  3. If they land on different machines, the second pod **can't plug in the disk** and stays stuck
     at `ContainerCreating`.
  4. Even when they share a machine, two programs writing one SQLite file at once is fragile and
     can lock or corrupt it.
  5. Upstream also has an *autoscaler* (HPA) that can start **more** server copies under load. Each
     new copy wants the same disk, so the more it scales, the worse it gets.
- **What we did:** used a real database server, **PostgreSQL**, exactly as Argilla's own
  docker-compose does. Postgres runs as its own pod with its own disk, and the server and worker
  connect to it **over the network**, like a website connecting to a database. They no longer
  share a disk, so they can run on any machine. We removed the autoscaler.

### 5.4 Database address format

- **What we did:** the chart gives Argilla the database address in the form
  `postgresql+asyncpg://user:password@host:5432/argilla`. The `+asyncpg` part names the database
  driver Argilla uses.
- **Why:** if Argilla is given a plain `postgresql://` address, it adds the driver name itself,
  using a find-and-replace on the whole address. That also changes any server name containing the
  word "postgresql", and our database service is called `argilla-postgresql`. Writing the full form
  ourselves means Argilla never needs to change it.
- **External databases:** addresses entered as `postgresql://`, `postgres://` or
  `postgresql+psycopg2://` are converted automatically. If you put the address in your own Secret
  (`externalDatabase.existingSecret`), write it with `postgresql+asyncpg://` yourself.

### 5.5 Elasticsearch (search)

- **What upstream did:** asked the **ECK operator**, a separate Elastic add-on, to create
  Elasticsearch.
- **Why it doesn't fit:** PCAI doesn't have ECK installed. The chart would ask for something nobody
  can provide, so search would never start.
- **What we did:** run Elasticsearch directly as a simple single-node service inside the chart, with
  a setting (`node.store.allow_mmap=false`) so it doesn't need special permissions on the machine.
  You can still point the chart at an existing Elasticsearch or OpenSearch.

### 5.6 Redis (job queue)

- **What upstream did:** pulled in a Redis chart from Bitnami's public internet repository.
- **Why it doesn't fit:** many PCAI sites are **air-gapped** (no internet), and Bitnami has since
  moved those images, so the old references break.
- **What we did:** run the official `redis:7-alpine` image directly. One small pod, nothing
  downloaded from extra chart repositories.

### 5.7 Passwords and keys

- **What upstream did:** hard-coded defaults like password `12345678` and API key `CHANGE_ME`.
- **Why it doesn't fit:** anyone who has read the upstream chart knows them.
- **What we did:** the chart generates random passwords and keys on first install and stores them
  in a Kubernetes **Secret**. On upgrades it reuses the same values, so nobody gets locked out.

### 5.8 Pinned version

- **Upstream:** uses image tag `latest`.
- **Why it doesn't fit:** `latest` changes over time, so two installs a week apart could run
  different code.
- **What we did:** pinned it to `v2.8.0`.

### 5.9 Start-up order and health checks

- **Upstream:** starts everything at once with no health checks.
- **Why it doesn't fit:** the server starts before Postgres is ready, crashes and restarts in a
  loop for a while.
- **What we did:**
  - The server and worker **wait** until Postgres, Elasticsearch and Redis answer before they start.
  - Health checks call `/api/v1/version`, so Kubernetes knows when Argilla is really up.
  - Pods wait for their Istio network proxy before starting.

### 5.10 Leftovers removed

- A broken ServiceAccount template.
- A minikube-only hack that edited `/etc/hosts`.
- The autoscaler (see 5.3).

### 5.11 PCAI single sign-on

Upstream Argilla has its own users and passwords. On PCAI, people should use their normal PCAI
login instead. Three pieces make that work.

**1. The "Sign in with Keycloak" button**

- Argilla already supports Keycloak logins. The chart turns that on and points it at PCAI's
  Keycloak (realm `UA`, client `ua`).
- PCAI supplies the client ID and secret during import through its `${OIDC_CLIENT_ID}` and
  `${OIDC_CLIENT_SECRET}` placeholders.

**2. Trusting PCAI's certificate**

- PCAI's Keycloak uses an HTTPS certificate signed by PCAI's **own** certificate authority (CA),
  which the Argilla image doesn't know about.
- The chart copies PCAI's root CA (`istio-system/ezaf-root-ca`, read-only) into Argilla's namespace
  and tells Argilla to trust it. You can also supply the CA yourself (`ezua.sso.caCert`).
- If Keycloak can't be reached when Argilla starts, Argilla still starts. Only the Keycloak button
  is switched off, and the log explains why.

**3. The SSO bridge (`files/pcai_sso.py`)**

- **Why it's needed:** after logging in, the Argilla web page attaches a "pass" (a token Argilla
  created) to every request. Every request passes through PCAI's gateway, and its login guard
  (oauth2-proxy) replaces that pass with the user's Keycloak pass. Argilla on its own doesn't
  recognise Keycloak's pass.
- **What it does:** a small piece of Python runs **inside the Argilla pod**, in front of Argilla.
  For each request:
  - **It carries an Argilla pass:** passed through unchanged.
  - **It carries a Keycloak pass:** the bridge checks it's genuinely signed by PCAI's Keycloak, so
    it can't be faked. It then creates the user in Argilla on their first visit and swaps in an
    Argilla pass for that same user.
  - **Anything else:** left alone, and Argilla rejects it as usual.
- **How it's loaded:** through a setting the Argilla image already provides (`UVICORN_APP`), so
  Argilla's normal start-up steps still run.
- Nothing outside Argilla's own namespace is changed.

**Roles:** new users start as **annotators** in the `default` workspace. The Keycloak realm roles
`argilla_role:owner` / `argilla_role:admin` / `argilla_role:annotator` set a user's Argilla role,
and `argilla_workspace:<name>` adds them to a workspace.

---

## 6. What gets installed

| Object | Where | What it's for |
|---|---|---|
| Deployment `<rel>-argilla` | Argilla namespace | Argilla server (web UI + API), port 6900 |
| Deployment `<rel>-argilla-worker` | Argilla namespace | Background jobs |
| StatefulSet `<rel>-argilla-postgresql` | Argilla namespace | Database, with its own 5 Gi disk |
| StatefulSet `<rel>-argilla-elasticsearch` | Argilla namespace | Search, with its own 10 Gi disk |
| Deployment `<rel>-argilla-redis` | Argilla namespace | Job queue (no disk needed) |
| Secret `<rel>-argilla` | Argilla namespace | Generated passwords, API key, signing key, DB address, Keycloak settings |
| Secret `<rel>-argilla-ca` | Argilla namespace | Copy of PCAI's root CA |
| ConfigMap `<rel>-argilla-pcai-sso` | Argilla namespace | The SSO bridge code |
| VirtualService | Argilla namespace | The tile's address |
| AuthorizationPolicy | `istio-system` | Standard PCAI login guard (`oauth2-proxy`). The **only** object outside Argilla's namespace |

**Uninstalling doesn't delete the Postgres and Elasticsearch disks.** Kubernetes keeps
StatefulSet disks on purpose. To start completely fresh, delete the namespace after uninstalling.

---

## 7. Installing

1. Package the chart: `helm package argilla` → `argilla-2.8.0.tgz`.
2. In PCAI, go to **Tools & Frameworks → Import Framework** and upload the `.tgz`. Use the `ezua:`
   section of `values.yaml` as the import values. PCAI fills in `${DOMAIN_NAME}` and the other
   placeholders only there.
3. In Keycloak, add Argilla's login address. In the **UA** realm, open **Clients → `ua` → Valid
   redirect URIs** and add:

   ```
   https://argilla.<your-domain>/oauth/keycloak/callback
   ```

   The oauth2-proxy address `https://argilla.<your-domain>/oauth2/callback` is usually already
   covered by a wildcard such as `https://*.<your-domain>/*`.
4. Open the tile and click **Sign in with Keycloak**.
5. Optional: give someone extra rights by creating a Keycloak realm role and assigning it:
   - `argilla_role:owner` for full control
   - `argilla_role:admin` to manage datasets
   - otherwise users are annotators

   For roles to apply through the Keycloak button, open **Client scopes → `roles` → Mappers →
   `realm roles`** and turn on **Add to userinfo**.
6. To get the built-in owner account (useful from notebooks):

   ```bash
   kubectl -n <ns> get secret <rel>-argilla -o jsonpath='{.data.username}' | base64 -d; echo
   kubectl -n <ns> get secret <rel>-argilla -o jsonpath='{.data.password}' | base64 -d; echo
   kubectl -n <ns> get secret <rel>-argilla -o jsonpath='{.data.api-key}'  | base64 -d; echo
   ```

7. From a PCAI notebook, use the internal address:

   ```python
   import argilla as rg
   client = rg.Argilla(api_url="http://<rel>-argilla.<ns>.svc.cluster.local:6900", api_key="<api-key>")
   ```

8. Check that every login policy on the gateway still uses `oauth2-proxy`:

   ```bash
   kubectl -n istio-system get authorizationpolicy \
     -o custom-columns=NAME:.metadata.name,ACTION:.spec.action,PROVIDER:.spec.provider.name
   # every CUSTOM row must say oauth2-proxy
   ```

---

## 8. How it was tested

- **Helm checks:** the chart passes Helm's strict lint and renders correctly in every mode:
  - built-in or external database, search and queue
  - SSO on or off
  - each way of supplying the CA
- **Provider guard:** the chart refuses any provider other than `oauth2-proxy`.
- **Labels:** every pod has the three PCAI labels.
- **Against the real Argilla 2.8.0 code:**
  - The database address keeps its hostname intact.
  - The Keycloak settings load correctly.
  - The SSO bridge passed 9 cases:
    - a real Keycloak token logs the user in and creates them
    - a repeat visit works
    - a Keycloak role makes them owner
    - a forged token, a wrong-issuer token and garbage are all rejected
    - a normal Argilla login still works
    - a new user lands in the `default` workspace
  - With Keycloak unreachable, the server still starts.
- **On a PCAI cluster:** the database connection, server start-up, CA trust, and the Keycloak login
  and token exchange were checked on a live PCAI cluster.

---

## 9. Updating to a newer Argilla version

1. Change the version in `Chart.yaml` (`version` and `appVersion`) and in `values.yaml`
   (`argilla.image.tag`, format `vX.Y.Z`).
2. Check that upstream hasn't changed the things this chart depends on:
   - **Docker image:** still has the `UVICORN_APP` setting and `start_argilla_server.sh`, and still
     runs as user 1000.
   - **Database address (5.4):** if upstream changes how it adds the driver name, the
     `postgresql+asyncpg://` form still works.
   - **Keycloak login:** still named `keycloak`, with callback `/oauth/keycloak/callback`.
   - **Code the bridge imports:** `argilla_server.app`, `contexts.accounts`,
     `database.AsyncSessionLocal`, `security.authentication.jwt.JWT`,
     `security.settings.settings.oauth_cfg`, `models.Workspace`.
   - **Health endpoint:** `/api/v1/version` still exists.
   - **Elasticsearch version:** still supported (match upstream's docker-compose).
3. Re-run the tests in section 8, install on a test PCAI cluster, and run the check in step 8 of
   section 7.

---

## Glossary

| Term | Meaning |
|---|---|
| **Pod** | One running copy of a program in Kubernetes |
| **Node** | A machine in the cluster that runs pods |
| **Deployment / StatefulSet** | Instructions that keep pods running. A StatefulSet also gives each pod its own permanent disk |
| **PVC / PV** | A disk request (PVC) and the actual disk (PV) |
| **ReadWriteOnce (RWO)** | A disk that can be attached to only one node at a time |
| **Secret / ConfigMap** | Stored settings. Secrets hold sensitive values |
| **Helm chart** | A package of Kubernetes files plus settings (`values.yaml`) |
| **Istio gateway** | The shared front door all PCAI apps are reached through |
| **VirtualService** | A routing rule: this address goes to that service |
| **AuthorizationPolicy** | A rule at the gateway that checks login before letting a request through |
| **oauth2-proxy** | PCAI's login guard; it sends users to Keycloak if they aren't logged in |
| **Keycloak** | PCAI's login system (single sign-on) |
| **Token** | The "pass" that proves who you are on each request |
| **CA (certificate authority)** | Whoever signs HTTPS certificates. PCAI has its own private one |
| **Air-gapped** | A cluster with no internet access |
