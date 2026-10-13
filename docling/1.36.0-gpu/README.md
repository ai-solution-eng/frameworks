# Docling PCAI AIE framework 1.36.0 (GPU Enabled)

- Framework version: 1.36.0
- Docling Serve version: 1.36.0
- External endpoint: `docling.${DOMAIN_NAME}`
- PVC uses the cluster default StorageClass when `storage.storageClassName` is empty.
- Set `storage.storageClassName` only when a specific class is required.
- Environment variables can be supplied through `env` and `envFrom`.

**NOTE**
Required by API-based picture description (OpenAI-compatible endpoint, local or cloud): the only remote service this container may call.
      - DOCLING_SERVE_ENABLE_REMOTE_SERVICES=True

## Typical configuration for Open Web UI witout image description
Set the below object in the __Admin Panel__ > __Settings__ > __Documents__

Content Extraction Engine `Docling`
```
http://[<optional, release name>-]<framework name e.g., docling>.<namespace e.g. docling>.svc.cluster.local:5001

example:
http://docling.docling.svc.cluster.local:5001

```
Enter Docling API Key   `<API KEY default null, if you don't se it in env var>`

Parameters
```
{
  "image_export_mode": "placeholder",
  "do_picture_description": false,
  "do_ocr": true,
  "ocr_preset": "auto",
  "pdf_backend": "dlparse_v4",
  "table_mode": "accurate"
}
```

## Typical configuration for Open Web UI for image description
Same as above.

Parameters
```
{
  "image_export_mode": "placeholder",
  "do_picture_description": true,
  "picture_description_api": "{\"url\": \"http:<model name>.<deployment name space>.svc.cluster.local/v1/chat/completions\", \"params\": {\"model\": \"<real model name>\"}, \"headers\": {\"Authorization\": \"Bearer <API KEY !!!pay attention to eventual values to be escaped!!!>\"},\"timeout\": 60, \"prompt\": \"Describe this image in great detail. Output the description as as a paragraph between two: --- separators.\"}",
  "do_ocr": true,
  "ocr_preset": "auto",
  "pdf_backend": "dlparse_v4",
  "table_mode": "accurate"
}
```

## Optional - Configuration of the Docling image description profiles 
It is possible to configure the *Docling image description profiles* setting the following `env` variable in the `values.yaml`:
```
- name: DOCLING_SERVE_CUSTOM_PICTURE_DESCRIPTION_PRESETS
  value: "{ \"image_desc_p1\": { \"model_spec\": { \"name\": \"Image description profile 1\", \"default_repo_id\": \"<model name>\", \"prompt\": \"Using the document language, describe this image in great detail, focusing on information relevant to the document. Output the description as a paragraph between two: --- separators.\", \"response_format\": \"plaintext\", \"supported_engines\": [\"api_openai\"] }, \"engine_options\": { \"engine_type\": \"api_openai\", \"url\": \"<model endpoint url>\", \"headers\": {\"Authorization\": \"Bearer <model API Key>\"}, \"params\": { \"model\": \"<model name>\", \"max_tokens\": 400}, \"timeout\": 300, \"concurrency\": 2 }, \"prompt\": \"Using the document language, describe this image in great detail, focusing on information relevant to the document. Output the description as a paragraph between two: --- separators.\", \"generation_config\": { \"max_new_tokens\": 400, \"do_sample\": false } } }"
```
*NOTE*: Please pay a strinct attention to this one-line variable configuration because a small typo could block the deployment. 

Then, the profile can be recalled from the Open Web UI (in the __Admin Panel__ > __Settings__ > __Documents__) using the following json:

```
{
  "image_export_mode": "placeholder",
  "do_picture_description": true,
  "picture_description_preset": "image_desc_p1",
  "do_ocr": true,
  "ocr_preset": "auto",
  "pdf_backend": "dlparse_v4",
  "table_mode": "accurate"
}
```


Ref. Documentation: `https://docs.openwebui.com/features/chat-conversations/rag/document-extraction/docling/`
