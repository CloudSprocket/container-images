# data-streams-consumer

Kafka/Redpanda consumer that reads a topic slowly so lag accumulates against a
faster producer.

Docker Hub:
[`cloudsprocket/data-streams-consumer`](https://hub.docker.com/r/cloudsprocket/data-streams-consumer)

## Purpose

Observe consumer lag and group behaviour under load. Pair with
`cloudsprocket/data-streams-producer` for a self-contained traffic demo in
integration tests and local setups.

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
| `KAFKA_TOPIC` | `events` | Topic to consume |
| `KAFKA_GROUP_ID` | `slow-consumer-group` | Consumer group id |
| `CONSUME_INTERVAL_SECONDS` | `1.0` | Delay after each message |
| `AUTO_OFFSET_RESET` | `earliest` | Offset reset policy |
| `CONNECT_RETRY_SECONDS` | `2.0` | Back-off while waiting for the broker |

## Quick start

Standalone against a local broker:

```bash
docker run --rm \
  -e KAFKA_BROKER=host.docker.internal:9092 \
  -e KAFKA_TOPIC=events \
  -e CONSUME_INTERVAL_SECONDS=1.0 \
  cloudsprocket/data-streams-consumer:latest
```

Full producer + slow consumer + Redpanda demo:

```bash
docker compose -f examples/data-streams/compose.yml up --build
```

## Versioning

This image versions independently. The current release is recorded in
[VERSION](VERSION). Git release tags take the form
`data-streams-consumer-v<version>`.

## Build

```bash
make build-data-streams-consumer
# or
docker buildx bake -f docker-bake.hcl data-streams-consumer --load
```
