# Porting NVIDIA NeMo Microservices to PCAI

NOTE: Use the ***nemo-microservices-25.8.0.tgz***. The nemo-microservices-25.8.0-[bitnami][archived][DO-NOT-USE].tar.gz package is not working due to the recent update of the bitnami/postgresql docker image change.

Bitnami recently [announced the deletion of the Bitnami public catalog](https://github.com/bitnami/containers/issues/83267) (docker.io/bitnami) that completed on Sep 29th 2025. The link to a Bitnami's PostgreSQL has been deliberately changed as Binami is moving towards [Bitnami Secure Images](https://news.broadcom.com/app-dev/broadcom-introduces-bitnami-secure-images-for-production-ready-containerized-applications). 

This is a **temporary** solution to overcome which is to find these deprecated images under the **bitnamilegacy** repo although note that these repos are no longer maintained or updated hence might have security vulnerabilities.

```sh
# WORKING
$ docker pull bitnamilegacy/postgresql:16.1.0-debian-11-r20 
# NOT WORKING
$ docker pull bitnami/postgresql:16.1.0-debian-11-r20 
```

## Todo

Replace <YOUR-NGC-API-KEY> with your actual NGC API key.

```yaml
# -- Your NVIDIA GPU Cloud (NGC) API key authenticates and enables pulling images from the NGC container registry. The existing secret overrides this key if you provide one to the `existingSecret` key.
ngcAPIKey: <YOUR-NGC-API-KEY>

# -- List of image pull secrets. Existing secrets override these values if you specify them. Use this only for experimentation when you want to hardcode a secret in your values file.
# @default -- `[{"name":"nvcrimagepullsecret","password":"YOUR-NGC-API-KEY","registry":"nvcr.io","username":"$$oauthtoken"}]`
imagePullSecrets:
  - name: nvcrimagepullsecret
    registry: nvcr.io
    username: $oauthtoken
    password: <YOUR-NGC-API-KEY>
```

## Setup Volcano

The NEMO operator requires Volcano for training job scheduling. If you run into the following error, the NEMO operator is failing because it can't find the Volcano scheduler CRD (PodGroup in version scheduling.volcano.sh/v1beta1)

```sh
# k logs -f nemo-microservices-nemo-operator-controller-manager-85ddbd8vzfz -n nemo
2025-10-05T23:36:23Z    ERROR   setup   unable to create controller     {"controller": "NemoTrainingJob", "error": "no matches for kind \"PodGroup\" in version \"scheduling.volcano.sh/v1beta1\""}
main.main
        /app/operators/nemo/cmd/main.go:175
runtime.main
        /usr/local/go/src/runtime/proc.go:272
```

#### Fix: Install Volcano Scheduler

```sh
# Install Volcano (latest stable version)
kubectl apply -f https://raw.githubusercontent.com/volcano-sh/volcano/master/installer/volcano-development.yaml


# Or for a specific version:

# For Volcano v1.9.0 (adjust version as needed)
kubectl apply -f https://raw.githubusercontent.com/volcano-sh/volcano/v1.9.0/installer/volcano-devel
```

#### Verify Installation
```sh
# Check Volcano pods are running
kubectl get pods -n volcano-system

# Verify PodGroup CRD is installed
kubectl get crd podgroups.scheduling.volcano.sh
```

## Modifications to the original chart.

How to download the orginal chart via a Helm CLI command. 

```sh
helm fetch https://helm.ngc.nvidia.com/nvidia/nemo-microservices/charts/nemo-microservices-helm-chart-25.8.0.tgz --username='$oauthtoken' --password=<YOUR-PASSWORD> --insecure-skip-tls-verify
```

### Changes in values.yaml

Add PCAI's virtual service using Istio gateway.

```yaml
ezua:
  #Use next options in order to configure the application endpoint.
  virtualService:
    endpoint: "nemo-microservices.${DOMAIN_NAME}"
    istioGateway: "istio-system/ezaf-gateway"
```

Set this to an empty string. The chart uses the `ngcAPIKey` value to generate the secret.

```yaml
# -- You can use an existing Kubernetes secret for pulling images. The chart uses the `ngcAPIKey` value to generate the secret if you set this to an empty string.
existingSecret: ""

# -- You can specify an existing Kubernetes image pull secret for pulling images from the container registry. The chart uses the `ngcAPIKey` value to generate the secret if you set this to an empty string.
existingImagePullSecret: ""
```