# data-streams-producer

Kafka/Redpanda load generator that floods a topic with synthetic events so you
can test lag, consumer groups and back-pressure.

Docker Hub:
[`cloudsprocket/data-streams-producer`](https://hub.docker.com/r/cloudsprocket/data-streams-producer)

## Purpose

Produce messages quickly against a configurable broker and topic. Pair with
`cloudsprocket/data-streams-consumer` (slow reader) to build consumer lag in
integration tests and local demos.

## Platforms

- `linux/amd64`
- `linux/arm64`

## Base and library pins

| Component | Version | Verification source (2026-08-11) |
| --- | --- | --- |
| Python base | `python:3.14.7-slim` | [Docker Hub official tags](https://hub.docker.com/_/python) |
| confluent-kafka | 2.15.0 | [PyPI](https://pypi.org/project/confluent-kafka/2.15.0/) |

`kafka-python` is not used; it is deprecated and unmaintained.

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `KAFKA_BROKER` | `localhost:9092` | Bootstrap server list |
| `KAFKA_TOPIC` | `events` | Topic to produce to |
| `PRODUCE_INTERVAL_SECONDS` | `0.1` | Delay between messages |
| `CONNECT_RETRY_SECONDS` | `2.0` | Back-off while waiting for the broker |

## Quick start

Standalone against a local broker:

```bash
docker run --rm \
  -e KAFKA_BROKER=host.docker.internal:9092 \
  -e KAFKA_TOPIC=events \
  -e PRODUCE_INTERVAL_SECONDS=0.1 \
  cloudsprocket/data-streams-producer:latest
```

Full producer + slow consumer + Redpanda demo:

```bash
docker compose -f examples/data-streams/compose.yml up --build
```

## Versioning

This image versions independently. The current release is recorded in
[VERSION](VERSION). Git release tags take the form
`data-streams-producer-v<version>`.

## Build

```bash
make build-data-streams-producer
# or
docker buildx bake -f docker-bake.hcl data-streams-producer --load
```
