{{- define "kargo-observability.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kargo-observability.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "kargo-observability.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kargo-observability.labels" -}}
app.kubernetes.io/name: {{ include "kargo-observability.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{/*
part-of names what this belongs to, and that is Kargo -- not the delivery kit
it was written inside. It shares no contract with anything in that kit and now
ships on its own. `kargo` also matches what the Kargo charts themselves write,
so everything observing one installation carries one label.

Changing this relabels existing objects on the next sync. That is a handful of
objects and the old value was simply wrong; a label nobody can act on is worse
than a moment of churn.
*/}}
app.kubernetes.io/part-of: kargo
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "kargo-observability.prefix" -}}
{{- .Values.metricPrefix | default "kargo" -}}
{{- end -}}
