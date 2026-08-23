# Changelog

All notable changes to `kargo-observability`. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning is semver.

## [0.1.0] - 2026-08-23

First release from a repository of its own. Written inside
`gitops_homelab_2_0` as part of a delivery kit and separated from it because it
shares no contract with the other pieces -- no code references it, the pipelines
chart does not reference it, and it is useful to anyone running Kargo whether or
not they want a gate or a triage agent.

Licensed **PolyForm Internal Use 1.0.0** rather than Apache 2.0: run it for
your own business, commercially, without asking; do not distribute it.

### Added

- `CustomResourceState` config for kube-state-metrics covering Promotion,
  Stage, Warehouse and Freight — nine metrics, no additional exporter.
- ClusterRole and binding granting the existing kube-state-metrics
  ServiceAccount read access to Kargo's CRDs, so no edit to that chart's own
  RBAC values is required.
- Eight alert rules, each individually toggleable with configurable `for` and
  `severity`, including `KargoMetricsMissing` — an `absent()` check without
  which every other rule fails open.
- A Grafana dashboard: current pipeline state, the two tables worth acting on,
  promotion and verification history, and freight age per warehouse.
- `values.schema.json` covering the full values contract.
