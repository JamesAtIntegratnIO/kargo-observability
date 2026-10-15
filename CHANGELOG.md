# Changelog

All notable changes to `kargo-observability`. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning is semver.

## [0.1.2] - 2026-10-15

### Fixed

- `KargoPromotionErrored` and `KargoPromotionFailed` fired once per Promotion
  object, and Promotion objects outlive the attempt. A stage that errored and
  then promoted successfully kept alerting until the old object was garbage
  collected: on one install 38 of 98 Errored and 16 of 20 Failed alerts were for
  stages whose latest promotion had succeeded. Both now read
  `kargo_stage_last_promotion_phase`, which gains a `promotion` label naming the
  stage's last promotion.
- `kargo_freight_discovered` gave every Freight of a warehouse the same label
  set, so Prometheus rejected all but one sample per scrape
  (`PrometheusDuplicateTimestamps`, ~900 warnings in 7.5h with 41 Freight) and
  kept an arbitrary one. It now carries a `freight` label.

## [0.1.1] - 2026-08-23

### Fixed

- A stray blank line in every object's `labels:` block. The comment explaining
  `part-of` was written `{{/* ... */}}` rather than `{{- /* ... */}}`, so it
  emitted the newline it was chomping on. Harmless YAML, visible in all five
  objects, and caught by diffing the published chart's render against the tree
  rather than by reading it.

  0.1.0 was already published and the release workflow refuses to overwrite a
  published version, which is why this is 0.1.1 rather than a re-push. That is
  the policy working, not getting in the way.

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
