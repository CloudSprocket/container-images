# CloudSprocket Container Images

[![CI](https://github.com/CloudSprocket/container-images/actions/workflows/ci.yml/badge.svg)](https://github.com/CloudSprocket/container-images/actions/workflows/ci.yml)
[![Licence: MIT](https://img.shields.io/badge/licence-MIT-blue.svg)](LICENSE)

Single-purpose utility containers published by CloudSprocket. Each image does
one job: pull it, run it, discard it.

## Supported images

| Image | Docker Hub repository | Purpose | Platforms |
| --- | --- | --- | --- |
| sec-forge | [`cloudsprocket/sec-forge`](https://hub.docker.com/r/cloudsprocket/sec-forge) | CI security scanning toolbox (Trivy, Grype, Semgrep, Checkov) | amd64, arm64 |
| mesh-router | [`cloudsprocket/mesh-router`](https://hub.docker.com/r/cloudsprocket/mesh-router) | Configurable HAProxy front end with rate limiting and stats | amd64, arm64 |
| data-streams-producer | [`cloudsprocket/data-streams-producer`](https://hub.docker.com/r/cloudsprocket/data-streams-producer) | Kafka/Redpanda load generator (producer) | amd64, arm64 |
| data-streams-consumer | [`cloudsprocket/data-streams-consumer`](https://hub.docker.com/r/cloudsprocket/data-streams-consumer) | Kafka/Redpanda load generator (slow consumer) | amd64, arm64 |

Each image has its own Docker Hub repository and its own version line. Use a
semantic-version tag for a reproducible pull or `latest` for the current
verified release of that image. See [SUPPORT.md](SUPPORT.md) for lifecycle
notes and [RELEASE.md](RELEASE.md) for the release tag format.

## Quick start

Requirements: Docker Engine or Docker Desktop, and Compose for the demos.

### sec-forge

Interactive scanner shell with Trivy, Grype, Semgrep and Checkov:

```bash
docker run --rm -it -v "${PWD}:/workspace" cloudsprocket/sec-forge:latest
```

### mesh-router

Two-backend demo with stick-table rate limiting and a stats page on `:8404`:

```bash
docker compose -f images/mesh-router/examples/compose.yml up --build
```

Browse `http://127.0.0.1/` for the load-balanced front end and
`http://127.0.0.1:8404/stats` for HAProxy stats.

### data-streams

Producer and slow consumer against Redpanda:

```bash
docker compose -f examples/data-streams/compose.yml up --build
```

## Build from source

```bash
make build
```

Or build a single image:

```bash
make build-sec-forge
make build-mesh-router
make build-data-streams-producer
make build-data-streams-consumer
```

Multi-architecture builds use Docker Buildx bake:

```bash
docker buildx bake -f docker-bake.hcl all
```

## Versioning and tags

Images version independently. Each image keeps its own
`images/<name>/VERSION` file. A shared monorepo version would be meaningless:
sec-forge tracks scanner releases, mesh-router tracks HAProxy, and the
data-streams images track their Python client stack.

Git release tags are per image:

```text
sec-forge-v0.1.0
mesh-router-v0.1.0
data-streams-producer-v0.1.0
data-streams-consumer-v0.1.0
```

Each release publishes two tags that share one multi-arch digest:

```text
docker.io/cloudsprocket/<name>:latest
docker.io/cloudsprocket/<name>:<version>
```

## Image documentation

- [sec-forge](images/sec-forge/README.md)
- [mesh-router](images/mesh-router/README.md)
- [data-streams-producer](images/data-streams-producer/README.md)
- [data-streams-consumer](images/data-streams-consumer/README.md)

## Project documents

- [Support policy](SUPPORT.md)
- [Security policy](SECURITY.md)
- [Contributing](CONTRIBUTING.md)
- [Release process](RELEASE.md)
- [Changelog](CHANGELOG.md)

## Licence

[MIT](LICENSE)
