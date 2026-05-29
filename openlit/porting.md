# Porting
This chart was created using the [subchart](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/) method. No modifications were made to the upstream openlit chart itself. Rather, the upstream chart is added a [dependency](https://helm.sh/docs/helm/helm_dependency/) in the parent `chart.yaml`, which contains additional necessary PCAI resources.

When creating a new version, `chart.yaml` should be edited with the following modifications:
```yaml
version: 1.20.0 # modify with new openlit chart version
appVersion: "1.20.0" # modify with new openlit app version
dependencies:
  - name: openlit
    alias: openlit
    version: 1.20.0 # modify with new openlit chart version
    repository: "https://openlit.github.io/helm/"
```

Then, run `helm dependency update` and build the chart as normal.

If any [values](https://github.com/openlit/helm/blob/main/charts/openlit/values.yaml) need to be changed from the openlit subchart, they can be addressed in the global `values.yaml` under the `openlit` key.