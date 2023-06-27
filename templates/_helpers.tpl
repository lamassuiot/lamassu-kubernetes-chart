{{- define "downstream.certSecret" -}}
  {{- if .Values.tls.selfSigned -}}
    {{- print "downstream-cert" -}}
  {{- else -}}
    {{- print .Values.tls.secretName -}}
  {{- end -}}
{{- end -}}

{{- define "postgres.hostname" -}}
  {{- print (ternary "postgresql-pgpool" .Values.externalPostgres.hostname .Values.integratedPostgres.enabled) -}}
{{- end -}}
{{- define "postgres.port" -}}
  {{- print (ternary "5432" .Values.externalPostgres.port .Values.integratedPostgres.enabled) -}}
{{- end -}}
{{- define "postgres.username" -}}
  {{- print (ternary .Values.integratedPostgres.global.postgresql.username .Values.externalPostgres.username .Values.integratedPostgres.enabled) -}}
{{- end -}}
{{- define "postgres.password" -}}
  {{- print (ternary .Values.integratedPostgres.global.postgresql.password .Values.externalPostgres.password .Values.integratedPostgres.enabled) -}}
{{- end -}}

{{- define "apiGateway.upstreamJwksCluster.url" -}}
  {{- $url := .Values.auth.oidc.apiGateway.jwksUrl -}}
  {{- $parsedUrl := (split "/" $url) -}}
  {{- $domain := ($parsedUrl._2) -}}
  {{- print $domain -}}
{{- end -}}

{{- define "opa.claimPath" -}}
  {{- $rolesClaim := .Values.auth.authorization.rolesClaim -}}
  {{- $split := (split "." $rolesClaim) -}}
  {{- $result := "" -}}
  {{- range $index, $part := $split -}}
    {{- $result = printf "%s[\"%s\"]" $result $part -}}
  {{- end -}}
  {{- print $result -}}
{{- end -}}