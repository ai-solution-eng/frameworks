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

| Folder   | Chart version | appVersion | Image                                 | Device |
| -------- | ------------- | ---------- | ------------------------------------- | ------ |
| 1.7.0    | 0.0.1         | v1.7.0     | `docling-project/docling-serve`       | CPU    |
| 1.13.0   | 0.0.1         | v1.13.0    | `docling-project/docling-serve-cu128` | GPU    |
| 1.28.0   | 0.0.2         | v1.28.0    | `docling-project/docling-serve-cu128` | GPU    |

## Key differences

- **1.7.0** — CPU-only build. Uses the base `docling-serve` image with no GPU
  resources requested and only the `DOCLING_SERVE_ENABLE_UI` env var.
- **1.13.0** — Switches to the CUDA image (`-cu128`). Adds `DOCLING_DEVICE=cuda`
  and `UVICORN_WORKERS=1` env vars and requests/limits an `nvidia.com/gpu`.
- **1.28.0** — Same GPU-based configuration as 1.13.0, tracking the newer
  `docling-serve`, Add template.metadata.labels in deployment to make it compatible with AIE 1.12.

Common resources across versions: 1 CPU / 1Gi memory requested (up to 4 CPU /
8Gi limit) and a 100Gi `gl4f-filesystem` PVC. GPU variants additionally reserve
one NVIDIA GPU.

## Reference

- docling-serve: https://github.com/docling-project/docling-serve
- Docling project: https://github.com/docling-project/docling
