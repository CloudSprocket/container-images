param(
    [switch]$Apply,
    [string]$Image
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$namespace = 'cloudsprocket'
$sourceUrl = 'https://github.com/CloudSprocket/container-images'
$contributingUrl = 'https://github.com/CloudSprocket/container-images/blob/main/CONTRIBUTING.md'
$websiteUrl = 'https://cloudsprocket.org'
$server = 'https://index.docker.io/v1/'

function Read-ImageVersion {
    param([string]$Name)

    $path = Join-Path $repoRoot "images/$Name/VERSION"
    if (-not (Test-Path -Path $path)) {
        throw "Missing VERSION file for image '${Name}' at ${path}."
    }
    $value = (Get-Content -Path $path -Raw).Trim()
    if ($value -notmatch '^\d+\.\d+\.\d+$') {
        throw "Version '${value}' for image '${Name}' is not a semantic major.minor.patch value."
    }
    return $value
}

$catalog = @(
    @{
        Name = 'sec-forge'
        Description = 'CI security scanning toolbox with pinned Trivy, Grype, Semgrep and Checkov.'
        Summary = 'Ubuntu 24.04 toolbox shipping Trivy, Grype, Semgrep and Checkov for vulnerability and IaC scanning in CI or local shells.'
        Use = @'
```console
docker pull cloudsprocket/sec-forge:__VERSION__
docker run --rm -it -v "${PWD}:/workspace" cloudsprocket/sec-forge:__VERSION__
```
'@
    }
    @{
        Name = 'mesh-router'
        Description = 'Configurable HAProxy 3.4 LTS front end with rate limiting and a stats endpoint.'
        Summary = 'HAProxy 3.4 LTS reverse proxy with stick-table rate limiting, active health checks and runtime-configurable backends.'
        Use = @'
```console
docker pull cloudsprocket/mesh-router:__VERSION__
docker run --rm -p 80:80 -p 8404:8404 \
  -e BACKEND_SERVERS="app1:8080,app2:8080" \
  cloudsprocket/mesh-router:__VERSION__
```
'@
    }
    @{
        Name = 'data-streams-producer'
        Description = 'Kafka/Redpanda load generator that produces synthetic events for consumer-lag testing.'
        Summary = 'Fast Kafka/Redpanda producer of synthetic events for load generation and consumer-lag testing.'
        Use = @'
```console
docker pull cloudsprocket/data-streams-producer:__VERSION__
docker run --rm \
  -e KAFKA_BROKER=broker:9092 \
  cloudsprocket/data-streams-producer:__VERSION__
```
'@
    }
    @{
        Name = 'data-streams-consumer'
        Description = 'Slow Kafka/Redpanda consumer for building and observing consumer lag.'
        Summary = 'Slow Kafka/Redpanda consumer designed to accumulate lag against a faster producer.'
        Use = @'
```console
docker pull cloudsprocket/data-streams-consumer:__VERSION__
docker run --rm \
  -e KAFKA_BROKER=broker:9092 \
  cloudsprocket/data-streams-consumer:__VERSION__
```
'@
    }
)

if (-not [string]::IsNullOrWhiteSpace($Image)) {
    $catalog = @($catalog | Where-Object { $_.Name -eq $Image })
    if ($catalog.Count -eq 0) {
        throw "Unknown image '${Image}'."
    }
}

foreach ($entry in $catalog) {
    if ($entry.Description.Length -gt 100) {
        throw "Description for $($entry.Name) exceeds Docker Hub's 100-character limit."
    }
}

$credentialJson = $server | & docker-credential-desktop.exe get
if ($LASTEXITCODE -ne 0) {
    throw 'Docker Desktop did not return Docker Hub credentials.'
}

$credential = $credentialJson | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($credential.Username) -or [string]::IsNullOrWhiteSpace($credential.Secret)) {
    throw 'The Docker Hub credential is incomplete.'
}

$tokenRequest = @{
    identifier = $credential.Username
    secret = $credential.Secret
} | ConvertTo-Json

$tokenResponse = Invoke-RestMethod `
    -Method Post `
    -Uri 'https://hub.docker.com/v2/auth/token' `
    -ContentType 'application/json' `
    -Body $tokenRequest

if ([string]::IsNullOrWhiteSpace($tokenResponse.access_token)) {
    throw 'Docker Hub authentication did not return an access token.'
}

$headers = @{ Authorization = "Bearer $($tokenResponse.access_token)" }

$overviewTemplate = @'
# __TITLE__

__SUMMARY__

## Supported platforms

- `linux/amd64`
- `linux/arm64`

## Tags

- `latest`: current supported release
- `__VERSION__`: immutable release

## Use

__USE__

## Links

- Source code: __SOURCE__
- Contributing guidelines: __CONTRIBUTING__
- Organisation website: __WEBSITE__
'@

foreach ($entry in $catalog) {
    $version = Read-ImageVersion -Name $entry.Name
    $title = $entry.Name
    $overview = $overviewTemplate.
        Replace('__TITLE__', $title).
        Replace('__SUMMARY__', $entry.Summary).
        Replace('__VERSION__', $version).
        Replace('__USE__', $entry.Use.Trim()).
        Replace('__SOURCE__', $sourceUrl).
        Replace('__CONTRIBUTING__', $contributingUrl).
        Replace('__WEBSITE__', $websiteUrl)

    # Docker-Sponsored Open Source compliance: description, source, contributing, website.
    foreach ($required in @($entry.Summary, $sourceUrl, $contributingUrl, $websiteUrl)) {
        if ($overview -notlike "*${required}*") {
            throw "Overview for $($entry.Name) is missing required compliance content: ${required}"
        }
    }

    $payload = @{
        description = $entry.Description
        full_description = $overview.Trim()
    } | ConvertTo-Json

    $uri = "https://hub.docker.com/v2/repositories/$namespace/$($entry.Name)/"
    if ($Apply) {
        $null = Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -ContentType 'application/json' -Body $payload
    }

    $current = Invoke-RestMethod -Method Get -Uri $uri
    [pscustomobject]@{
        repository = "$namespace/$($entry.Name)"
        version = $version
        applied = [bool]$Apply
        public = -not [bool]$current.is_private
        status = $current.status_description
        description = $current.description
        overview_length = ([string]$current.full_description).Length
    }
}
