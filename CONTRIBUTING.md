# Contributing

## The rule this chart exists to enforce

**A query that parses is not a query that works.**

Every alert expression here once parsed correctly against a live Prometheus and
matched nothing, for hours, because kube-state-metrics prefixes
custom-resource metrics unless told not to. Nothing failed. Dashboards were
empty and alerts were silent, which is what a healthy system looks like.

So: `hack/lint.sh` runs `promtool` because an expression that does not parse is
a rule that never loads — but passing it proves only that. **Any change to a
metric name, a label, or the CustomResourceState config must be checked against
a live Prometheus for a NON-EMPTY result** before you believe it.

`KargoMetricsMissing` is the backstop. It is the one rule that can fire without
the metrics it watches, and it is what caught the original incident. Do not
weaken it.

## Two things that will bite you

- **kube-state-metrics reads its config once, at startup.** Nothing watches the
  ConfigMap. Change it and restart, or you will spend an afternoon debugging a
  correct config against a pod emitting the old series.
- **Phase is a `StateSet`, not an `Info`.** Promotions accumulate forever. A
  per-object series is a cardinality bomb, not a metric.

## No environment assumptions

Nothing may assume a cluster name, namespace, domain, or a particular
kube-prometheus-stack release name. Those are values, with a schema.

## Checks

```bash
hack/lint.sh   # helm lint, values.schema.json, promtool
```

## Versioning

Semver, and the git tag must equal `Chart.yaml`'s `version` — CI refuses a tag
that disagrees, and refuses to overwrite a version already published.

## License

Contributions are accepted under [PolyForm Internal Use 1.0.0](LICENSE). By
opening a pull request you agree your contribution may be relicensed by the
copyright holder, including under commercial terms.
