# Porting Guide: PaddleOCR-VL + Gotenberg on HPE AIE (PCAI)

## What This Is

A headless document OCR pipeline deployed on HPE Private Cloud AI via BYOA (Bring Your Own Application). Upload a `.docx`, `.pptx`, or `.pdf` and get structured text back.

```
User → [Adapter :8080] → [Gotenberg :3000] → PDF → [Layout Detection (ONNX/CPU)] → [VLM on MLIS (GPU)]
                                                                                            ↓
                                                                                    Structured markdown
```

## Components

| Component | Where it runs | What it does |
|-----------|--------------|--------------|
| **PaddleOCR-VL 0.9B** | MLIS (Tier 1, GPU) | Vision-language model for text/table/formula recognition |
| **Adapter** | Helm chart pod (Tier 2, CPU) | Orchestrates the pipeline, runs layout detection via ONNX |
| **Gotenberg** | Helm chart pod (Tier 2, CPU) | Converts docx/pptx to PDF via LibreOffice |

## Quick Test

From any pod on the cluster:

```bash
# Health check
curl -s http://paddleocr-vl-pipeline-vl-api.paddleocr-vl-pipeline.svc.cluster.local:8080/health

# OCR an image
curl -X POST http://paddleocr-vl-pipeline-vl-api.paddleocr-vl-pipeline.svc.cluster.local:8080/ocr \
  -F "file=@myimage.png"

# OCR a docx (goes through Gotenberg first)
curl -X POST http://paddleocr-vl-pipeline-vl-api.paddleocr-vl-pipeline.svc.cluster.local:8080/ocr \
  -F "file=@report.docx"

# OCR a pptx
curl -X POST http://paddleocr-vl-pipeline-vl-api.paddleocr-vl-pipeline.svc.cluster.local:8080/ocr \
  -F "file=@slides.pptx"
```

## Response Format

```json
{
  "filename": "report.docx",
  "pages": [
    {
      "page": 1,
      "blocks": [
        {"label": "title", "bbox": [x1,y1,x2,y2], "score": 0.95, "content": "Quarterly Report"}
      ]
    }
  ],
  "markdown": "# Quarterly Report\n\n...",
  "elapsed_seconds": 12.3
}
```

## Supported File Types

| Type | Flow |
|------|------|
| `.pdf` | → layout detection → VLM |
| `.png` `.jpg` `.jpeg` `.tiff` `.bmp` `.webp` | → layout detection → VLM |
| `.docx` `.doc` `.pptx` `.ppt` `.xlsx` `.xls` `.odt` `.odp` `.rtf` | → Gotenberg → PDF → layout detection → VLM |

## Key Configuration (values.yaml)

```yaml
vlApi:
  pipeline:
    vlmServerUrl: "<mlis-endpoint>/v1"
    vlmModelName: "PaddlePaddle/PaddleOCR-VL"
    layoutEnabled: true      # false to skip layout detection
    layoutDevice: "cpu"      # "cpu" or "cuda"
  mlisAuth:
    enabled: true
    apiKey: "<mlis-token>"
```
