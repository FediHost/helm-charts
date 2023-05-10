{{/*
Expand the name of the chart.
*/}}
{{- define "calckey.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "calckey.fullname" -}}
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
{{- define "calckey.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "calckey.labels" -}}
helm.sh/chart: {{ include "calckey.chart" . }}
{{ include "calckey.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "calckey.selectorLabels" -}}
app.kubernetes.io/name: {{ include "calckey.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "calckey.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "calckey.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified name for dependent services.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "calckey.elasticsearch.fullname" -}}
{{- printf "%s-%s" .Release.Name "elasticsearch" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "calckey.redis.fullname" -}}
{{- printf "%s-%s" .Release.Name "redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "calckey.postgresql.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
config/default.yml content
*/}}
{{- define "calckey.configDir.default.yml" -}}
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Calckey configuration
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#   ┌─────┐
#───┘ URL └─────────────────────────────────────────────────────

# Final accessible URL seen by a user.
url: "https://{{ .Values.calckey.domain }}/"

# ONCE YOU HAVE STARTED THE INSTANCE, DO NOT CHANGE THE
# URL SETTINGS AFTER THAT!

#   ┌───────────────────────┐
#───┘ Port and TLS settings └───────────────────────────────────

#
# Misskey requires a reverse proxy to support HTTPS connections.
#
#                 +----- https://example.tld/ ------------+
#   +------+      |+-------------+      +----------------+|
#   | User | ---> || Proxy (443) | ---> | Misskey (3000) ||
#   +------+      |+-------------+      +----------------+|
#                 +---------------------------------------+
#
#   You need to set up a reverse proxy. (e.g. nginx)
#   An encrypted connection with HTTPS is highly recommended
#   because tokens may be transferred in GET requests.

# The port that your Misskey server should listen on.
port: 3000

#   ┌──────────────────────────┐
#───┘ PostgreSQL configuration └────────────────────────────────

db:
  {{- if .Values.postgresql.enabled }}
  host: {{ template "calckey.postgresql.fullname" . }}
  port: '5432'
  {{- else }}
  host: {{ .Values.postgresql.postgresqlHostname }}
  port: {{ .Values.postgresql.postgresqlPort | default "5432" | quote }}
  {{- end }}

  # Database name
  db: {{ .Values.postgresql.auth.database }}

  # Auth
  user: {{ .Values.postgresql.auth.username }}
  pass: "{{ .Values.postgresql.auth.password }}"

  # Whether disable Caching queries
  #disableCache: true

  # Extra Connection options
  #extra:
  #  ssl: true

#   ┌─────────────────────┐
#───┘ Redis configuration └─────────────────────────────────────

redis:
  {{- if .Values.redis.enabled }}
  host: {{ template "calckey.redis.fullname" . }}-master
  {{- else }}
  host: {{ required "When the redis chart is disabled .Values.redis.hostname is required" .Values.redis.hostname }}
  {{- end }}
  port: {{ .Values.redis.port | default "6379" | quote }}
  #family: 0  # 0=Both, 4=IPv4, 6=IPv6
  pass: {{ .Values.redis.auth.password | quote }}
  #prefix: example-prefix
  #db: 1

#   ┌─────────────────────┐
#───┘ Sonic configuration └─────────────────────────────────────

#sonic:
#  host: localhost
#  port: 1491
#  auth: SecretPassword
#  collection: notes
#  bucket: default

#   ┌─────────────────────────────┐
#───┘ Elasticsearch configuration └─────────────────────────────

{{- if .Values.elasticsearch.enabled }}
elasticsearch:
  host: {{ template "mastodon.elasticsearch.fullname" . }}-master-hl
  port: 9200
  ssl: false
{{- else if .Values.elasticsearch.hostname }}
elasticsearch:
  host: {{ .Values.elasticsearch.hostname | quote }}
  port: {{ .Values.elasticsearch.port }}
  ssl: {{ .Values.elasticsearch.ssl }}
  {{- if .Values.elasticsearch.auth }}
  user: {{ .Values.elasticsearch.auth.username | quote }}
  pass: {{ .Values.elasticsearch.auth.password | quote }}
  {{- end }}
{{- end }}

#   ┌───────────────┐
#───┘ ID generation └───────────────────────────────────────────

# You can select the ID generation method.
# You don't usually need to change this setting, but you can
# change it according to your preferences.

# Available methods:
# aid ... Short, Millisecond accuracy
# meid ... Similar to ObjectID, Millisecond accuracy
# ulid ... Millisecond accuracy
# objectid ... This is left for backward compatibility

# ONCE YOU HAVE STARTED THE INSTANCE, DO NOT CHANGE THE
# ID SETTINGS AFTER THAT!

id: 'aid'

#   ┌─────────────────────┐
#───┘ Other configuration └─────────────────────────────────────

# Max note length, should be < 8000.
#maxNoteLength: 3000

# Maximum lenght of an image caption or file comment (default 1500, max 8192)
#maxCaptionLength: 1500

# Reserved usernames that only the administrator can register with
reservedUsernames:
{{ .Values.calckey.reservedUsernames | toYaml }}

# Whether disable HSTS
#disableHsts: true

# Number of worker processes
#clusterLimit: 1

# Job concurrency per worker
# deliverJobConcurrency: 128
# inboxJobConcurrency: 16

# Job rate limiter
# deliverJobPerSec: 128
# inboxJobPerSec: 16

# Job attempts
# deliverJobMaxAttempts: 12
# inboxJobMaxAttempts: 8

# IP address family used for outgoing request (ipv4, ipv6 or dual)
#outgoingAddressFamily: ipv4

# Syslog option
#syslog:
#  host: localhost
#  port: 514

# Proxy for HTTP/HTTPS
#proxy: http://127.0.0.1:3128

#proxyBypassHosts: [
#  'example.com',
#  '192.0.2.8'
#]

# Proxy for SMTP/SMTPS
#proxySmtp: http://127.0.0.1:3128   # use HTTP/1.1 CONNECT
#proxySmtp: socks4://127.0.0.1:1080 # use SOCKS4
#proxySmtp: socks5://127.0.0.1:1080 # use SOCKS5

# Media Proxy
#mediaProxy: https://example.com/proxy

# Proxy remote files (default: false)
#proxyRemoteFiles: true

allowedPrivateNetworks:
{{ .Values.calckey.allowedPrivateNetworks | toYaml }}

# TWA
#twa:
#  nameSpace: android_app
#  packageName: tld.domain.twa
#  sha256CertFingerprints: ['AB:CD:EF']

# Upload or download file size limits (bytes)
#maxFileSize: 262144000

# Managed hosting settings
# !!!!!!!!!!
# >>>>>> NORMAL SELF-HOSTERS, STAY AWAY! <<<<<<
# >>>>>> YOU DON'T NEED THIS! <<<<<<
# !!!!!!!!!!
# Each category is optional, but if each item in each category is mandatory!
# If you mess this up, that's on you, you've been warned...

#maxUserSignups: 100
isManagedHosting: {{ .Values.calckey.isManagedHosting }}
deepl:
  managed: false
#  authKey: ''
#  isPro: false
#
email:
  managed: {{ .Values.calckey.smtp.managed }}
  address: {{ .Values.calckey.smtp.from_address | quote }}
  host: {{ .Values.calckey.smtp.server | quote }}
  port: {{ .Values.calckey.smtp.port }}
  user: {{ .Values.calckey.smtp.login | quote }}
  pass: {{ .Values.calckey.smtp.password | quote }}
  useImplicitSslTls: {{ .Values.calckey.smtp.useImplicitSslTls }}
objectStorage:
  managed: {{ .Values.calckey.objectStorage.managed }}
  baseUrl: {{ .Values.calckey.objectStorage.baseUrl | quote }}
  bucket: {{ .Values.calckey.objectStorage.bucket | quote }}
  prefix: {{ .Values.calckey.objectStorage.prefix | quote }}
  endpoint: {{ .Values.calckey.objectStorage.endpoint | quote }}
  region: {{ .Values.calckey.objectStorage.region | quote }}
  accessKey: {{ .Values.calckey.objectStorage.access_key | quote }}
  secretKey: {{ .Values.calckey.objectStorage.access_secret | quote }}
  useSsl: true
  connnectOverProxy: false
  setPublicReadOnUpload: true
  s3ForcePathStyle: true

# !!!!!!!!!!
# >>>>>> AGAIN, NORMAL SELF-HOSTERS, STAY AWAY! <<<<<<
# >>>>>> YOU DON'T NEED THIS, ABOVE SETTINGS ARE FOR MANAGED HOSTING ONLY! <<<<<<
# !!!!!!!!!!

# Seriously. Do NOT fill out the above settings if you're self-hosting.
# They're much better off being set from the control panel.
{{- end }}
