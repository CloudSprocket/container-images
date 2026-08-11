#!/usr/bin/env bash
# Smoke-test a built local image. Proves runtime behaviour, not merely build.
set -Eeuo pipefail

image_name="${1:-}"
tag="${2:-dev}"
namespace="${IMAGE_NAMESPACE:-docker.io/cloudsprocket}"

usage() {
  echo "Usage: ./scripts/smoke-test.sh <image-name> [tag]" >&2
  echo "Known images: sec-forge mesh-router data-streams-producer data-streams-consumer" >&2
  exit 2
}

[[ -n "$image_name" ]] || usage

reference="${namespace}/${image_name}:${tag}"
prefix="smoke-${image_name//\//-}-$$"
cleanup_cmds=()

cleanup() {
  local cmd
  for cmd in "${cleanup_cmds[@]}"; do
    # shellcheck disable=SC2086
    eval $cmd >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

wait_for_log() {
  local container="$1"
  local pattern="$2"
  local attempts="${3:-30}"
  local i
  for ((i = 1; i <= attempts; i++)); do
    if docker logs "$container" 2>&1 | grep -Eq "$pattern"; then
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for '${pattern}' in logs of ${container}" >&2
  docker logs "$container" >&2 || true
  return 1
}

smoke_sec_forge() {
  local shell_mode
  # Non-login and login shells must both resolve scanners. A PATH-on-login
  # shell defect has bitten this estate before.
  for shell_mode in bash-c bash-lc; do
    echo "sec-forge: checking scanners under ${shell_mode}"
    case "$shell_mode" in
      bash-c)
        docker run --rm --name "${prefix}-c" "$reference" \
          bash -c '
            set -euo pipefail
            for tool in trivy grype semgrep checkov; do
              command -v "$tool"
            done
            trivy --version
            grype version
            semgrep --version
            checkov --version
          '
        ;;
      bash-lc)
        docker run --rm --name "${prefix}-lc" "$reference" \
          bash -lc '
            set -euo pipefail
            for tool in trivy grype semgrep checkov; do
              command -v "$tool"
            done
            trivy --version
            grype version
            semgrep --version
            checkov --version
          '
        ;;
    esac
  done
  echo "sec-forge smoke test passed."
}

smoke_mesh_router() {
  local network="${prefix}-net"
  local backend="${prefix}-web"
  local router="${prefix}-router"

  docker network create "$network" >/dev/null
  cleanup_cmds+=("docker network rm ${network}")

  docker run -d --rm --name "$backend" --network "$network" \
    docker.io/library/nginx:alpine >/dev/null
  cleanup_cmds+=("docker stop ${backend}")

  docker run -d --name "$router" --network "$network" \
    -p 127.0.0.1::8404 \
    -e BACKEND_SERVERS="${backend}:80" \
    "$reference" >/dev/null
  cleanup_cmds+=("docker rm -f ${router}")

  # Resolve the published host port for the stats endpoint.
  local mapped
  mapped="$(docker port "$router" 8404/tcp | head -n1 | awk -F: '{print $NF}')"
  [[ -n "$mapped" ]] || {
    echo "mesh-router: could not resolve published stats port" >&2
    docker logs "$router" >&2 || true
    exit 1
  }

  local i
  for ((i = 1; i <= 20; i++)); do
    if curl -fsS "http://127.0.0.1:${mapped}/stats" | grep -Eqi 'Statistics Report|HAProxy'; then
      echo "mesh-router smoke test passed (stats on host port ${mapped})."
      return 0
    fi
    sleep 1
  done

  echo "mesh-router: stats endpoint did not become ready" >&2
  docker logs "$router" >&2 || true
  exit 1
}

smoke_data_streams_pair() {
  local role="$1"
  local network="${prefix}-net"
  local broker="${prefix}-redpanda"
  local container="${prefix}-${role}"

  docker network create "$network" >/dev/null
  cleanup_cmds+=("docker network rm ${network}")

  docker run -d --rm --name "$broker" --network "$network" \
    docker.io/redpandadata/redpanda:v25.3.15 \
    redpanda start --smp 1 --memory 512M --overprovisioned \
    --kafka-addr internal://0.0.0.0:9092 \
    --advertise-kafka-addr internal://"${broker}":9092 >/dev/null
  cleanup_cmds+=("docker stop ${broker}")

  case "$role" in
    producer)
      docker run -d --name "$container" --network "$network" \
        -e KAFKA_BROKER="${broker}:9092" \
        -e KAFKA_TOPIC=events \
        -e PRODUCE_INTERVAL_SECONDS=0.2 \
        -e CONNECT_RETRY_SECONDS=1.0 \
        "$reference" >/dev/null
      cleanup_cmds+=("docker rm -f ${container}")
      wait_for_log "$container" 'Connected to broker'
      wait_for_log "$container" 'Produced:'
      ;;
    consumer)
      # Optional seed when the producer image is already present locally.
      if docker image inspect "${namespace}/data-streams-producer:${tag}" >/dev/null 2>&1; then
        docker run -d --name "${prefix}-seed" --network "$network" \
          -e KAFKA_BROKER="${broker}:9092" \
          -e KAFKA_TOPIC=events \
          -e PRODUCE_INTERVAL_SECONDS=0.2 \
          -e CONNECT_RETRY_SECONDS=1.0 \
          "${namespace}/data-streams-producer:${tag}" >/dev/null
        cleanup_cmds+=("docker rm -f ${prefix}-seed")
        wait_for_log "${prefix}-seed" 'Connected to broker' || true
      fi

      docker run -d --name "$container" --network "$network" \
        -e KAFKA_BROKER="${broker}:9092" \
        -e KAFKA_TOPIC=events \
        -e KAFKA_GROUP_ID=smoke-consumer \
        -e CONSUME_INTERVAL_SECONDS=0.2 \
        -e CONNECT_RETRY_SECONDS=1.0 \
        "$reference" >/dev/null
      cleanup_cmds+=("docker rm -f ${container}")
      wait_for_log "$container" 'Connected to broker'
      ;;
    *)
      echo "internal error: unknown data-streams role ${role}" >&2
      exit 1
      ;;
  esac

  echo "data-streams-${role} smoke test passed."
}

case "$image_name" in
  sec-forge)
    smoke_sec_forge
    ;;
  mesh-router)
    smoke_mesh_router
    ;;
  data-streams-producer)
    smoke_data_streams_pair producer
    ;;
  data-streams-consumer)
    smoke_data_streams_pair consumer
    ;;
  *)
    usage
    ;;
esac
