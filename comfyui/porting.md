
make sure in values.yaml, cpu and memory limits have been defined:
resources:
```
  limits:
    cpu: 8
    memory: 30Gi
    nvidia.com/gpu: 1
  requests:
    cpu: 4
    memory: 1Gi
    nvidia.com/gpu: 1
```