# kargo-observability

Kargo's own state as Prometheus metrics, plus alerts and a dashboard.

Kargo exposes controller-runtime counters and nothing else — no promotion,
freight, stage or verification state. So a promotion that fails, a verification
that errors, or a target that has been broken since the day it was written sits
in the API and appears nowhere. This chart closes that gap without an exporter,
by configuring kube-state-metrics' `CustomResourceState` over Kargo's CRDs.

> **Status: live.** Running in production since 2026-08-22, against Kargo 1.11.
> Every alert expression is checked against a live Prometheus for a non-empty
> result — see *Parsing is not evidence* below for why that wording matters.

## What it ships

- **Metrics** — promotion phase, stage last-promotion and verification phase,
  warehouse freight age, per-object creation timestamps. Phase is modelled as a
  `StateSet` rather than a per-object `Info`, so `count by (stage, phase)` works
  without one series per promotion name. Promotions accumulate; cardinality is
  a design constraint, not an afterthought.
- **Alerts** — promotion errored, promotion failed, promotion running long,
  verification failed, warehouse stale, stage behind. Plus `KargoMetricsMissing`,
  an `absent()` check on the metrics themselves: kube-state-metrics is usually
  a tracked artifact in its own right, and a subchart bump that invalidates the
  config would otherwise silence every other alert here.
- **A dashboard** — promotions by phase, failures with age, time-to-merge,
  stale stages, verification pass rate, and how much is parked on a human.

## Requirements

kube-state-metrics, with `customResourceState.enabled` and the matching
`rbac.extraRules`. Both are set by this chart; the host chart must allow them
to be passed through.

## Reference

- [`docs/metrics.md`](docs/metrics.md) — the metric contract: names, labels, cardinality
- [`docs/alerts.md`](docs/alerts.md) — every rule, what it means, how to tune it

## Parsing is not evidence

The one operational lesson this chart exists to carry.

On the day it shipped, every alert expression parsed correctly against a live
Prometheus and matched **nothing**, for hours. kube-state-metrics prefixes
custom-resource metrics with `kube_customresource_` unless the resource sets
`metricNamePrefix`, which the config did not — so 168 series were flowing
within two minutes, into names nothing queried.

Nothing failed. Every dashboard was empty and every alert was silent, which is
exactly what a healthy system looks like.

The rule that follows: **a query that parses is not a query that works.** After
any change here, assert a non-empty result, not a valid expression. The alert
that caught it was `KargoMetricsMissing`, the one rule in the set that can fire
without the metrics it watches.

Two smaller ones, learned the same way:

- **kube-state-metrics reads its CustomResourceState config once, at startup.**
  Changing the ConfigMap changes nothing until it restarts. In production this
  cost a rollout to notice: the config was correct and the running pod kept
  emitting the old series.
- **Phase is a `StateSet`, not an `Info`.** Promotions accumulate forever, so a
  per-object series is a cardinality bomb rather than a metric.

## License

[PolyForm Internal Use 1.0.0](LICENSE).

**You may run it for your own business, commercially, in production, without
asking anyone.** That is the whole point — it solves a problem anyone running
Kargo has, and nothing here is trying to make that inconvenient.

**You may not distribute it.** Not sold, not bundled into a product, not
offered as a hosted service, not handed on. Providing it to third parties in
any form needs a separate licence.

That is stricter than "don't sell it": it rules out free redistribution too, so
no public forks and no deploying it on a client's behalf. Installing it from
the registry is *use*, not distribution, so ordinary adoption is unaffected.

Want to ship it inside something? Ask — a commercial licence is available and
that is the intended path, not an afterthought.

## Provenance

Written inside [`gitops_homelab_2_0`](https://github.com/JamesAtIntegratnIO/gitops_homelab_2_0)
as part of a delivery kit, alongside a pre-merge gate and an LLM triage agent
that now live in [`bosun`](https://github.com/JamesAtIntegratnIO/bosun).

It was separated from those deliberately: it shares no contract with either,
and it is useful to anyone running Kargo whether or not they want a gate or an
agent.

The licences differ for the same reason. Bosun is PolyForm **Noncommercial** —
nobody profits from it but its author. This is PolyForm **Internal Use** —
anyone may profit *using* it, nobody may profit *from* it.
