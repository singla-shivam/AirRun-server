{{/*
Expand the name of the chart.
*/}}
{{- define "air-run-deploy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "air-run-deploy.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "air-run-deploy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "air-run-deploy.labels" -}}
helm.sh/chart: {{ include "air-run-deploy.chart" . }}
{{ include "air-run-deploy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "air-run-deploy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "air-run-deploy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "air-run-deploy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- printf "%s-%s" (include "air-run-deploy.fullname" .) "sa" -}}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of persistent volume to use
*/}}
{{- define "air-run-deploy.persistentVolumeName" -}}
{{- printf "%s-%s" (include "air-run-deploy.fullname" .) "pv" -}}
{{- end  }}

{{/*
Create the name of persistent volume claim to use
*/}}
{{- define "air-run-deploy.persistentVolumeClaimName" -}}
{{- printf "%s-%s" (include "air-run-deploy.fullname" .) "pv-claim" -}}
{{- end  }}

{{/*
Create the name of persistent volume storage to use
*/}}
{{- define "air-run-deploy.persistentVolumeStorageName" -}}
{{- printf "%s-%s" (include "air-run-deploy.fullname" .) "pv-storage" -}}
{{- end  }}

{{/*
Create the name of role-binding to use
*/}}
{{- define "air-run-deploy.roleBindingName" -}}
{{- printf "%s-%s" (include "air-run-deploy.fullname" .) "rb" -}}
{{- end  }}

{{/*
Create the name of role to use
*/}}
{{- define "air-run-deploy.roleName" -}}
{{- printf "%s-%s" (include "air-run-deploy.fullname" .) "role" -}}
{{- end  }}
