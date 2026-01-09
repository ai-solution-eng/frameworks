# Porting
This chart was created using the [subchart](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/) method. No modifications were made to the upstream phoenix chart itself. Rather, the upstream chart is added a [dependency](https://helm.sh/docs/helm/helm_dependency/) in the parent `chart.yaml`, which contains additional necessary PCAI resources.

When creating a new version, `chart.yaml` should be edited with the following modifications:
```yaml
version: 4.0.17 # modify with new phoenix chart version
appVersion: "12.19.0" # modify with new phoenix app version
dependencies:
  - name: phoenix-helm
    alias: phoenix
    version: 4.0.17 # modify with new phoenix chart version
    repository: "oci://registry-1.docker.io/arizephoenix"
```

Then, run `helm dependency update` and build the chart as normal.

If any [values](https://hub.docker.com/r/arizephoenix/phoenix-helm) need to be changed from the phoenix subchart, they can be addressed in the global `values.yaml` under the `phoenix` key.