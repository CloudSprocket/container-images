# Security policy

## Reporting a vulnerability

Use the repository's private security advisory form when available, or contact
the maintainers privately. Do not disclose an unpatched vulnerability in a
public issue.

Include the affected image name, tag or digest, platform, reproduction steps
and expected impact. Maintainers will acknowledge a complete report as soon as
practical and coordinate remediation and disclosure.

## Supported versions

Security fixes target the current moving channel (`latest`) and the newest
versioned release recorded in each image's `images/<name>/VERSION` file. See
[SUPPORT.md](SUPPORT.md) for image lifecycle notes.

## Important limitations

These are single-purpose utility containers. They are intended to be run for a
job and discarded. They are not multi-tenant platforms and are not hardened as
long-lived production servers.

- `sec-forge` is a CI scanning toolbox. Run it on trusted development hosts or
  in CI; do not expose it as a multi-tenant service.
- `mesh-router` exposes an unauthenticated HAProxy stats page on port 8404 for
  local observation. Do not publish that port on an untrusted network.
- The data-streams images generate synthetic Kafka/Redpanda traffic. They hold
  no credentials by default; supply broker authentication only when you need
  it and never bake secrets into a published tag.

Never mount the Docker socket into these containers unless you fully accept
the privilege implications.
