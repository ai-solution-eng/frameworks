# Porting
This chart was created using the [subchart](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/) method. No modifications were made to the upstream phoenix chart itself. Rather, the upstream chart is added a [dependency](https://helm.sh/docs/helm/helm_dependency/) in the parent `chart.yaml`, which contains additional necessary PCAI resources.

When creating a new version, `chart.yaml` should be edited with the following modifications:
```yaml
version: 0.39.0 # modify with new headlamp chart version
appVersion: "0.39.0" # modify with new headlamp app version
dependencies:
  - name: headlamp
    alias: headlamp
    version: 0.39.0 # modify with new headlamp chart version
    repository: "https://kubernetes-sigs.github.io/headlamp/"
```

Then, run `helm dependency update` and build the chart as normal.

If any [values](https://artifacthub.io/packages/helm/headlamp/headlamp) need to be changed from the headlamp subchart, they can be addressed in the global `values.yaml` under the `headlamp` key.