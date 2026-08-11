"""Flood a Kafka/Redpanda topic with synthetic events."""

from __future__ import annotations

import json
import os
import sys
import time

from confluent_kafka import KafkaException, Producer


def env_str(name: str, default: str) -> str:
    value = os.environ.get(name, default)
    return value if value else default


def env_float(name: str, default: float) -> float:
    raw = os.environ.get(name)
    if raw is None or raw == "":
        return default
    try:
        return float(raw)
    except ValueError as exc:
        raise SystemExit(f"{name} must be a number, got {raw!r}") from exc


BROKER = env_str("KAFKA_BROKER", "localhost:9092")
TOPIC = env_str("KAFKA_TOPIC", "events")
INTERVAL = env_float("PRODUCE_INTERVAL_SECONDS", 0.1)
CONNECT_RETRY_SECONDS = env_float("CONNECT_RETRY_SECONDS", 2.0)


def wait_for_producer() -> Producer:
    """Create a producer and confirm the broker answers metadata requests."""
    while True:
        producer = Producer({"bootstrap.servers": BROKER})
        try:
            producer.list_topics(timeout=5)
            print(f"Connected to broker {BROKER}", flush=True)
            return producer
        except KafkaException as exc:
            print(f"Waiting for broker... {exc}", flush=True)
            time.sleep(CONNECT_RETRY_SECONDS)


def delivery_report(err, msg) -> None:
    if err is not None:
        print(f"Delivery failed: {err}", file=sys.stderr, flush=True)


def main() -> None:
    producer = wait_for_producer()
    counter = 0
    print(
        f"Producing to topic={TOPIC!r} interval={INTERVAL}s",
        flush=True,
    )
    while True:
        message = {
            "id": counter,
            "timestamp": time.time(),
            "event": "user_click",
        }
        payload = json.dumps(message).encode("utf-8")
        try:
            producer.produce(TOPIC, value=payload, callback=delivery_report)
        except BufferError:
            producer.poll(1.0)
            producer.produce(TOPIC, value=payload, callback=delivery_report)
        producer.poll(0)
        print(f"Produced: {message}", flush=True)
        counter += 1
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
