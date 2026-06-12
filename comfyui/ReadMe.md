# ComfyUI Deployment on HPE PCAI

## Overview

**ComfyUI** is a powerful AI creation engine for visual professionals who require full control over models, parameters, workflows, and outputs. Its modular node-based interface enables users to build sophisticated workflows for generating:

* Images
* Videos
* Audio
* 3D Models
* AI-powered creative content

ComfyUI natively supports many of the latest open-source state-of-the-art AI models. Through API nodes, it can also integrate with leading closed-source models and services such as Nano Banana, Seedance, Hunyuan3D, and others.

Complex workflows can be simplified and exposed through user-friendly interfaces using **App Mode**, while its API capabilities allow seamless integration into enterprise and production pipelines.

---

## Repository Contents

This repository contains all the artifacts required to deploy ComfyUI on an **HPE Private Cloud AI (PCAI)** environment.

### Included Components

| Component           | Description                                                               |
| ------------------- | ------------------------------------------------------------------------- |
| `comfyui-0.1.1.tgz` | Helm chart used to deploy ComfyUI on HPE PCAI                             |
| `Dockerfile`        | Custom Docker image build definition                                      |
| `entrypoint.sh`     | Startup script that installs and configures custom nodes and dependencies |

---

## Helm Chart

Use the following Helm chart for deployment:

```bash
comfyui-0.1.1.tgz
```

The chart deploys ComfyUI as a Kubernetes workload and can be customized through Helm values to suit your environment.

---

## Custom Docker Image

The repository includes a custom Docker image build process for ComfyUI.

The Docker image contains several modifications compared to the default ComfyUI installation:

* Controlled installation of PyTorch and CUDA dependencies
* Additional system libraries required by custom nodes
* Automated installation of selected custom nodes
* Runtime configuration of ComfyUI-Manager
* Startup validation and dependency management
* The image `nchanduka/comfyui:latest` is present on open source Docker Hub, built using this Dockerfile and entrypoint.sh and ready to use. It has bene pre-populated into the values.yaml.

---

## Custom Entrypoint

The included `entrypoint.sh` performs additional initialization tasks during container startup.

### ComfyUI-Manager Installation

The script automatically installs and configures:

* ComfyUI-Manager

Configuration settings are applied automatically to ensure stable operation in containerized environments.

### Custom Node Installation

The following custom nodes are automatically cloned and installed during the first container startup:

| Custom Node                 | Repository                                         |
| --------------------------- | -------------------------------------------------- |
| ComfyUI-Manager             | https://github.com/ltdrdata/ComfyUI-Manager        |
| ComfyUI Essentials          | https://github.com/cubiq/ComfyUI_essentials        |
| ComfyUI Crystools           | https://github.com/crystian/ComfyUI-Crystools      |
| rgthree-comfy               | https://github.com/rgthree/rgthree-comfy           |
| ComfyUI-KJNodes             | https://github.com/kijai/ComfyUI-KJNodes           |
| ComfyUI Ultimate SD Upscale | https://github.com/ssitu/ComfyUI_UltimateSDUpscale |

The entrypoint script also installs all required Python dependencies for these custom nodes.

---

## Dependency Management

This repository includes important modifications to the standard ComfyUI installation process.

The upstream ComfyUI project:

https://github.com/Comfy-Org/ComfyUI

installs dependencies dynamically through its `requirements.txt` file. Over time, this can introduce compatibility issues as newer versions of PyTorch, CUDA libraries, and related packages become available.

To ensure consistent and reproducible deployments on HPE PCAI, the Docker build process:

* Pins specific versions of PyTorch components
* Controls CUDA runtime compatibility - **CUDA 12.8**
* Prevents unintended upgrades of critical GPU libraries
* Ensures compatibility with the target NVIDIA driver stack
* Maintains stability across ComfyUI and custom node installations

These modifications help avoid dependency conflicts and provide a predictable deployment experience.

---

## Deployment Workflow

1. Build the custom ComfyUI Docker image.
2. Push the image to your container registry.
3. Deploy the Helm chart to your HPE PCAI Kubernetes cluster.
4. Access the ComfyUI web interface through the configured service endpoint.
5. Install models and workflows as required.

---

## References

* ComfyUI: https://github.com/Comfy-Org/ComfyUI
