# Changelog

All notable changes are documented here. Entries are grouped by image where
releases diverge.

## Unreleased

### Repository

- Reframed the project as CloudSprocket Container Images: single-purpose
  utility containers.
- Removed the shared root `VERSION` file. Each image now versions independently
  under `images/<name>/VERSION`.
- Added multi-arch bake file, path-filtered CI, per-image release workflow,
  weekly clean rebuild, smoke tests and Docker Hub metadata tooling.

## sec-forge 0.1.0 - 2026-08-11

### Added

- Published `cloudsprocket/sec-forge`, an Ubuntu 24.04 security scanning
  toolbox with pinned Trivy, Grype, Semgrep and Checkov on amd64 and arm64.

## mesh-router 0.1.0 - 2026-08-11

### Added

- Published `cloudsprocket/mesh-router`, HAProxy 3.4 LTS with stick-table rate
  limiting, a stats endpoint and runtime-configurable backends.

## data-streams-producer 0.1.0 - 2026-08-11

### Added

- Published `cloudsprocket/data-streams-producer`, a Kafka/Redpanda load
  generator using `confluent-kafka` on a current Python slim base.

## data-streams-consumer 0.1.0 - 2026-08-11

### Added

- Published `cloudsprocket/data-streams-consumer`, a slow Kafka/Redpanda
  consumer for building and observing consumer lag.
