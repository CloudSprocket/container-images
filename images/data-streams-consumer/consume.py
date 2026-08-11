"""Read a Kafka/Redpanda topic slowly to create consumer lag."""

from __future__ import annotations

import json
import os
import time

from confluent_kafka import Consumer, KafkaError, KafkaException


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
GROUP_ID = env_str("KAFKA_GROUP_ID", "slow-consumer-group")
INTERVAL = env_float("CONSUME_INTERVAL_SECONDS", 1.0)
CONNECT_RETRY_SECONDS = env_float("CONNECT_RETRY_SECONDS", 2.0)
AUTO_OFFSET_RESET = env_str("AUTO_OFFSET_RESET", "earliest")


def wait_for_consumer() -> Consumer:
    """Create a consumer once the broker answers metadata requests."""
    while True:
        consumer = Consumer(
            {
                "bootstrap.servers": BROKER,
                "group.id": GROUP_ID,
                "auto.offset.reset": AUTO_OFFSET_RESET,
                "enable.auto.commit": True,
            }
        )
        try:
            consumer.list_topics(timeout=5)
            consumer.subscribe([TOPIC])
            print(
                f"Connected to broker {BROKER} topic={TOPIC!r} group={GROUP_ID!r}",
                flush=True,
            )
            return consumer
        except KafkaException as exc:
            consumer.close()
            print(f"Waiting for broker/topic... {exc}", flush=True)
            time.sleep(CONNECT_RETRY_SECONDS)


def main() -> None:
    consumer = wait_for_consumer()
    print(f"Consuming slowly interval={INTERVAL}s", flush=True)
    try:
        while True:
            msg = consumer.poll(1.0)
            if msg is None:
                continue
            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    continue
                print(f"Consumer error: {msg.error()}", flush=True)
                continue

            raw = msg.value()
            try:
                value = json.loads(raw.decode("utf-8")) if raw is not None else None
            except (UnicodeDecodeError, json.JSONDecodeError):
                value = raw

            print(f"Consumed: {value}", flush=True)
            time.sleep(INTERVAL)
    finally:
        consumer.close()


if __name__ == "__main__":
    main()
