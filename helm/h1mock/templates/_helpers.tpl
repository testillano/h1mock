{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "h1mock.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "h1mock.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "h1mock.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "h1mock.labels" -}}
app.kubernetes.io/name: {{ include "h1mock.name" . }}
helm.sh/chart: {{ include "h1mock.chart" . }}
{{ include "h1mock.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "h1mock.selectorLabels" -}}
app.kubernetes.io/name: {{ include "h1mock.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "h1mock.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "h1mock.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the provision config map
*/}}
{{- define "h1mock.configmap" }}
{{- $currentScope := ( first . ) -}}
{{- $scope := ( last . ) -}}
{{- $provisionsDir := $scope.service.provisionsDir -}}
{{- if ne "$provisionsDir" "" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $scope.service.name | lower | replace "_" "-" }}-provision-config
  labels:
{{ include "h1mock.labels" $currentScope | indent 4 }}
data:
{{ ( $currentScope.Files.Glob (print $provisionsDir "/*") ).AsConfig | indent 2 }}
{{- end -}}
{{- end -}}

