# OLLAMA Framework

Ollama is a lightweight framework designed to run large language models (LLMs) efficiently. When deployed on Kubernetes, Ollama provides a simple, container-friendly way to serve models such as LLaMA, Mistral, Gemma, and others without requiring complex inference stacks. Its architecture allows models to be pulled, cached, and executed on-demand inside pods, making it suitable for scalable, GPU-enabled clusters.

Ollama's REST API enables easy integration with microservices, and because it is packaged as a single self-contained runtime, it fits naturally into K8s workflows such as Deployments, Jobs, and Kubeflow Pipelines. Using Ollama on Kubernetes helps standardize LLM serving across environments while keeping deployments reproducible and portable
We ideally do not need OLLAMA on HPE PCAI, PCAI comes with HPE MLIS where you can deploy models for inferencing. 

# Deploying Multiple Models on a Single GPU with OLLAMA

HPE MLIS on AIE does not support the NVIDIA Multi-Instance GPU (MIG) feature up to version 1.10. As a result, deploying multiple models on a single GPU is not natively supported. While there are potential workarounds, they require custom configuration and additional effort.

By deploying OLLAMA as a framework, you can overcome this limitation and run multiple models concurrently on a single GPU.

This setup has been tested with AIE versions 1.6 and 1.10.

Once the framework is deployed, you can access the provided endpoint to interact with OLLAMA and manage your models.

**NOTE** You have to set the GPU parameters as below to allocate GPU to OLLAMA in the values.yaml.

```
# Ollama parameters
ollama:
  # Port Ollama is listening on
  port: 11434

  gpu:
    # -- Enable GPU integration
    enabled: true

    # -- Enable DRA GPU integration,if enabled, it will use DRA instead of Device Driver Plugin and create a ResourceClaim and GpuClaimParameters
    draEnabled: false

    # -- DRA GPU DriverClass
    draDriverClass: "gpu.nvidia.com"

    # -- Existing DRA GPU ResourceClaim Template
    draExistingClaimTemplate: ""

    # -- GPU type: 'nvidia' or 'amd'
    type: 'nvidia'

    # -- Specify the number of GPU, if you use MIG section below then this parameter is ignored
    number: 1

    # -- only for nvidia cards; change to (example) 'nvidia.com/mig-1g.10gb' to use MIG slice
    nvidiaResource: "nvidia.com/gpu"

    mig:
      enabled: false
      # -- Specify the mig devices and the corresponding number
      devices: {}
          #        1g.10gb: 1
          #        3g.40gb: 1

  models:
    # -- List of models to pull at container startup
    # pull:
    #  - llama2
    #  - mistral
    pull: []

    # -- List of models to load in memory at container startup
    # run:
    #  - llama2
    #  - mistral
    run: []

    # -- List of models to create at container startup, there are two options
	create: []
	
	# -- Automatically remove models present on the disk but not specified in the values file
	clean: false
	
  # -- Add insecure flag for pulling at container startup 
  insecure: false
  
  # -- Override ollama-data volume mount path, default: "/root/.ollama"                                                                                                                                                                                
  mountPath: ""
```

# Sample Snippets to work with OLLAMA Endpoint

## Pull models
You can find the list of available models which you can pull from https://ollama.com/search?q=llama

**Command**
```
curl https://ollama.<DOMAIN>/api/pull -d '{"model": "llama3.2:1b"}'
```
**Output**
```
{"status":"pulling manifest"}
{"status":"pulling 74701a8c35f6","digest":"sha256:74701a8c35f6c8d9a4b91f3f3497643001d63e0c7a84e085bed452548fa88d45","total":1321082688}
{"status":"pulling 74701a8c35f6","digest":"sha256:74701a8c35f6c8d9a4b91f3f3497643001d63e0c7a84e085bed452548fa88d45","total":1321082688}
{"status":"pulling 74701a8c35f6","digest":"sha256:74701a8c35f6c8d9a4b91f3f3497643001d63e0c7a84e085bed452548fa88d45","total":1321082688}
{"status":"pulling 74701a8c35f6","digest":"sha256:74701a8c35f6c8d9a4b91f3f3497643001d63e0c7a84e085bed452548fa88d45","total":1321082688,"completed":3791205}
{"status":"pulling 74701a8c35f6","digest":"sha256:74701a8c35f6c8d9a4b91f3f3497643001d63e0c7a84e085bed452548fa88d45","total":1321082688,"completed":54875392}
.....
.....
{"status":"pulling 4f659a1e86d7","digest":"sha256:4f659a1e86d7f5a33c389f7991e7224b7ee6ad0358b53437d54c02d2e1b1118d","total":485,"completed":485}
{"status":"verifying sha256 digest"}
{"status":"writing manifest"}
{"status":"success"}
```

## Sample Reqeust to Model - Python code 
```
import requests
import json
url = "https://ollama.<DOMAIN>/api/chat"
data = {
    "model": "llama3.2:1b",
    "messages": [
        {"role": "user", "content": "Capital of India?"}
    ]
}

# Stream response as it comes
with requests.post(url, json=data, stream=True) as r:
    for line in r.iter_lines():
        if line:
            obj = json.loads(line.decode("utf-8"))
            if "message" in obj:
                print(obj["message"]["content"], end="", flush=True)
            elif obj.get("done"):
                print("\n--- Chat complete ---")
```                

Save the file as ollama_request.py
Run the below command

**Output**
```
python .\ollama_requests.py

New Delhi is the capital of India
```
## Muitlple models on the single GPU on OLLAMA Framework.

**Command**
```
curl https://ollama.aie01.pcai.tryezmeral.com/api/tags | jq
```

**Output**

You see 2 models here

llama3.1:8b

llama3.2:1b

```
{
  "models": [
    {
      "name": "llama3.1:8b",
      "model": "llama3.1:8b",
      "modified_at": "2025-11-20T15:14:07.034127364Z",
      "size": 4920753328,
      "digest": "46e0c10c039e019119339687c3c1757cc81b9da49709a3b3924863ba87ca666e",
      "details": {
        "parent_model": "",
        "format": "gguf",
        "family": "llama",
        "families": [
          "llama"
        ],
        "parameter_size": "8.0B",
        "quantization_level": "Q4_K_M"
      }
    },
    {
      "name": "llama3.2:1b",
      "model": "llama3.2:1b",
      "modified_at": "2025-11-20T12:37:49.347827584Z",
      "size": 1321098329,
      "digest": "baf6a787fdffd633537aa2eb51cfd54cb93ff08e28040095462bb63daf552878",
      "details": {
        "parent_model": "",
        "format": "gguf",
        "family": "llama",
        "families": [
          "llama"
        ],
        "parameter_size": "1.2B",
        "quantization_level": "Q8_0"
      }
    }
  ]
}
```


