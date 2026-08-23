#!/usr/bin/env bash
# helm lint the chart, and check it against its own values.schema.json.
#
# The schema check is the point: it is the values contract for people who do
# not have this repository to read, and a schema that drifts from the chart is
# worse than no schema at all.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

command -v helm >/dev/null 2>&1 || { echo "needs helm on PATH" >&2; exit 2; }

fail=0
ok()  { printf '  \033[32mok\033[0m    %s\n' "$*"; }
bad() { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; fail=1; }

lintargs=()
for v in ci/*-values.yaml; do [ -f "$v" ] && lintargs+=(-f "$v"); done

if helm lint "${lintargs[@]}" . >/dev/null 2>&1; then ok "helm lint"; else
  helm lint "${lintargs[@]}" . 2>&1 | sed 's/^/        /'; bad "helm lint"
fi

# `helm template` validates values against values.schema.json when present, so
# a default set that violates its own schema fails here.
if helm template lint-check "${lintargs[@]}" . >/dev/null 2>&1; then
  ok "values.schema.json accepts the chart defaults"
else
  helm template lint-check "${lintargs[@]}" . 2>&1 | sed 's/^/        /' | head -10
  bad "chart defaults violate values.schema.json"
fi

python3 -c 'import json,sys; json.load(open("values.schema.json"))' 2>/dev/null \
  && ok "values.schema.json is valid JSON" || bad "values.schema.json is not valid JSON"

# Every alert expression must PARSE. It cannot be checked for a non-empty
# result here -- that needs a live Prometheus with Kargo running, and the gap
# between the two is the whole lesson in the README.
#
# promtool wants a bare Prometheus rules file, NOT a PrometheusRule CRD: the
# `groups:` it reads live under `.spec`, and handing it the whole manifest
# fails with "field apiVersion not found in type rulefmt.RuleGroups".
rules_ok=1
command -v promtool >/dev/null 2>&1 || { echo "  skip  promtool not on PATH (alert expressions unparsed)"; rules_ok=0; }
if [ "$rules_ok" = 1 ] && ! python3 -c 'import yaml' 2>/dev/null; then
  echo "  skip  python3 PyYAML missing (cannot extract .spec for promtool)"
  rules_ok=0
fi
if [ "$rules_ok" = 1 ]; then
  helm template lint-check "${lintargs[@]}" . --show-only templates/prometheusrule.yaml \
    | python3 -c 'import sys, yaml; yaml.safe_dump(yaml.safe_load(sys.stdin)["spec"], sys.stdout)' \
    > /tmp/kargo-rules.yaml
  if promtool check rules /tmp/kargo-rules.yaml >/dev/null 2>&1; then
    ok "promtool check rules ($(grep -c '^\s*- alert:' /tmp/kargo-rules.yaml) alerts parse)"
  else
    promtool check rules /tmp/kargo-rules.yaml 2>&1 | sed 's/^/        /' | head
    bad "promtool check rules"
  fi
fi

echo
[ "$fail" -eq 0 ] || { echo "LINT FAILED"; exit 1; }
echo "lint passed"
