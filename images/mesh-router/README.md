# mesh-router

HAProxy 3.4 LTS front end with stick-table rate limiting and a stats endpoint.
Backends are supplied at runtime so the published image works outside any
particular compose file.

Docker Hub: [`cloudsprocket/mesh-router`](https://hub.docker.com/r/cloudsprocket/mesh-router)

## Purpose

A configurable reverse-proxy container for traffic shaping, active health
checks and a round-robin backend pool. Useful as a disposable front end in
integration tests, demos and local multi-service setups.

## Platforms

- `linux/amd64`
- `linux/arm64`

## Base image

| Component | Tag | Verification source (2026-08-11) |
| --- | --- | --- |
| HAProxy | `haproxy:3.4.3` | [Docker Hub official tags](https://hub.docker.com/_/haproxy) (3.4 LTS; 3.4.3 present) |

## Configuration

### Runtime backends (default)

Set `BACKEND_SERVERS` to a comma-separated list of `host:port` values. The
entrypoint renders them into the baked template.

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `BACKEND_SERVERS` | yes (unless custom config) | none | Comma-separated backends, e.g. `web1:80,web2:80` |
| `HAPROXY_CONFIG` | no | unset | Absolute path to a full custom HAProxy config file |

Example:

```bash
docker run --rm -p 80:80 -p 8404:8404 \
  -e BACKEND_SERVERS="app1:8080,app2:8080" \
  cloudsprocket/mesh-router:latest
```

### Full custom config

Mount your own file and point `HAPROXY_CONFIG` at it:

```bash
docker run --rm -p 80:80 -p 8404:8404 \
  -v "${PWD}/my-haproxy.cfg:/config/haproxy.cfg:ro" \
  -e HAPROXY_CONFIG=/config/haproxy.cfg \
  cloudsprocket/mesh-router:latest
```

When `HAPROXY_CONFIG` is set, `BACKEND_SERVERS` is ignored.

### Built-in behaviour

The default template keeps:

- stick-table rate limiting: more than 10 requests per 10 seconds per source IP
  returns HTTP 429;
- active HTTP health checks on each backend;
- stats UI on port `8404` at `/stats`.

## Demo compose

Two nginx backends:

```bash
docker compose -f images/mesh-router/examples/compose.yml up --build
```

- Front end: `http://127.0.0.1/`
- Stats: `http://127.0.0.1:8404/stats`

## Versioning

This image versions independently. The current release is recorded in
[VERSION](VERSION). Git release tags take the form `mesh-router-v<version>`.

## Build

```bash
make build-mesh-router
# or
docker buildx bake -f docker-bake.hcl mesh-router --load
```
