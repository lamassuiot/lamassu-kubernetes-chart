{{- define "chart.namespace" -}}{{ .Release.Namespace }}{{- end -}}
{{- define "chart.name" -}}{{ .Release.Name }}{{- end -}}