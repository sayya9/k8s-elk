{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "es.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified es app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "es.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-es" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "filebeat.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-filebeat" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "logstash.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-logstash" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified es master name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "es.master.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-es-master" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified es data name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "es.data.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-es-data" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified es coordinator name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "es.coordinator.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-es-coordinator" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "labels" -}}
heritage: {{ .Release.Service }}
release: {{ .Release.Name }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app: {{ template "es.fullname" . }}
{{- end -}}

{{- define "labels.esMaster" -}}
release: {{ .Release.Name }}
app: {{ template "es.fullname" . }}
component: es-master
{{- end -}}

{{- define "labels.esData" -}}
release: {{ .Release.Name }}
app: {{ template "es.fullname" . }}
component: es-data
{{- end -}}

{{- define "labels.esCoordinator" -}}
release: {{ .Release.Name }}
app: {{ template "es.fullname" . }}
component: es-coordinator
{{- end -}}

{{- define "labels.filebeat" -}}
release: {{ .Release.Name }}
app: {{ template "filebeat.fullname" . }}
component: shipper
{{- end -}}

{{- define "labels.logstash" -}}
release: {{ .Release.Name }}
app: {{ template "filebeat.fullname" . }}
component: indexer
{{- end -}}
