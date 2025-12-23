# Porting

## values.yaml
No update. It does not need VirtualService to use. 

## Chart.yaml
change version name for PCAI compatibility.
```
version: v0.7.0 -> version: 0.7.0
```


# Notes
To download the original Chart
```bash
helm pull oci://registry.k8s.io/lws/charts/lws
```
