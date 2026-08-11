# sec-forge

Ubuntu 24.04 security scanning toolbox for CI and local workflows. Ships
Trivy, Grype, Semgrep and Checkov on `linux/amd64` and `linux/arm64`.

Docker Hub: [`cloudsprocket/sec-forge`](https://hub.docker.com/r/cloudsprocket/sec-forge)

## Purpose

Pull a ready interactive shell with common vulnerability and IaC scanners
without installing each tool on the host. Mount a project directory and scan
from `/workspace`. Suitable as a disposable CI job container or a local
scanner shell.

## Platforms

- `linux/amd64`
- `linux/arm64`

## Pinned tools

| Tool | Version | Verification source (2026-08-11) |
| --- | --- | --- |
| Trivy | 0.73.0 | [GitHub releases](https://github.com/aquasecurity/trivy/releases/tag/v0.73.0) |
| Grype | 0.117.0 | [GitHub releases](https://github.com/anchore/grype/releases/tag/v0.117.0) |
| Semgrep | 1.172.0 | [PyPI](https://pypi.org/project/semgrep/1.172.0/) |
| Checkov | 3.3.10 | [PyPI](https://pypi.org/project/checkov/3.3.10/) |

Trivy is installed from the Aqua Security apt repository using the `generic`
suite (the supported suite for current releases on Ubuntu 24.04; per-codename
suites such as `noble` no longer receive new packages after Trivy 0.72.0), a
keyring under `/etc/apt/keyrings`, and a pinned package version. Grype is
installed from a pinned GitHub release archive with checksum verification.

## Quick start

```bash
docker run --rm -it -v "${PWD}:/workspace" cloudsprocket/sec-forge:latest
```

Inside the container:

```bash
trivy fs .
grype dir:.
semgrep --config=auto .
checkov -d .
```

## Configuration

No required environment variables. Optional cache directories live under the
non-root `scanner` home directory when the tools download vulnerability
databases.

| Item | Value |
| --- | --- |
| Default user | `scanner` (uid 1000) |
| Working directory | `/workspace` |
| Default command | interactive `/bin/bash` |

## Versioning

This image versions independently. The current release is recorded in
[VERSION](VERSION). Git release tags take the form `sec-forge-v<version>`.

## Build

```bash
make build-sec-forge
# or
docker buildx bake -f docker-bake.hcl sec-forge --load
```

Multi-arch:

```bash
docker buildx bake -f docker-bake.hcl sec-forge \
  --set sec-forge.platform=linux/amd64,linux/arm64
```
