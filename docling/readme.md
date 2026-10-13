# Docling

Hand-crafted Helm chart to deploy [docling-serve](https://github.com/docling-project/docling-serve),
the document-processing service from the [Docling project](https://github.com/docling-project/docling).

The chart runs the upstream `docling-serve` container image on Kubernetes (HPE EzUA),
exposing the HTTP API and web UI on port `5001` and persisting data to a mounted PVC
(`/data`). Access is published through an Istio `VirtualService` at
`docling.${DOMAIN_NAME}`.

## Versions

Each folder is a self-contained chart pinned to a `docling-serve` release
(`appVersion`), sharing the same template structure (`deployment`, `service`,
`pvc`, `virtualService`).

| Folder       | Chart version | appVersion    | Image                                                 | Device |
| ------------ | ------------- | ------------- | ----------------------------------------------------- | ------ |
| 1.7.0        | 0.0.1         | v1.7.0        | `quay.io/docling-project/docling-serve`               | CPU    |
| 1.13.0       | 0.0.1         | v1.13.0       | `quay.io/docling-project/docling-serve-cu128`         | GPU    |
| 1.28.0       | 0.0.2         | v1.28.0       | `quay.io/docling-project/docling-serve-cu128`         | GPU    |
| 1.36.0-cpu   | 0.0.3         | 1.36.0-cpu    | `ghcr.io/docling-project/docling-serve:v1.36.0`       | CPU    |
| 1.36.0-gpu   | 0.0.3         | 1.36.0-gpu    | `ghcr.io/docling-project/docling-serve-cu128:v1.36.0` | GPU    |

## Key differences

- **1.7.0** — CPU-only build. Uses the base `docling-serve` image with no GPU
  resources requested and only the `DOCLING_SERVE_ENABLE_UI` env var.
- **1.13.0** — Switches to the CUDA image (`-cu128`). Adds `DOCLING_DEVICE=cuda`
  and `UVICORN_WORKERS=1` env vars and requests/limits an `nvidia.com/gpu`.
- **1.28.0** — Same GPU-based configuration as 1.13.0, tracking the newer
  `docling-serve`, Add template.metadata.labels in deployment to make it compatible with AIE 1.12.
- **1.36.0** — (2026-10-09) Docling with CPU-only and GPU-enabled configurations. Provides comprehensive parameterization through `values.yaml` (environment variables), allowing fine-grained tuning of Docling behavior. It is also preconfigured for image description (e.g., in Open Web UI), for furhter information see the `README.md` inside the `.tgz` package. Container images are sourced from the `docling-project` repository on `ghcr.io`.

Common resources across versions: 1 CPU / 1Gi memory requested (up to 4 CPU /
8Gi limit) and a 50-100Gi `gl4f-filesystem` PVC (on PCAI DevKits leave the StorageClass as default). GPU variants additionally reserve one NVIDIA GPU.

## Reference

- docling-serve: https://github.com/docling-project/docling-serve
- Docling project: https://github.com/docling-project/docling
