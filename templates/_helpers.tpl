{{- define "downstream.certSecret" -}}
  {{- if .Values.tls.selfSigned -}}
    {{- print "downstream-cert" -}}
  {{- else -}}
    {{- print .Values.tls.secretName -}}
  {{- end -}}
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