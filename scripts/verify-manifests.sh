#!/usr/bin/env bash
set -Eeuo pipefail

image_name="${1:-}"
version="${2:-}"

[[ -n "$image_name" && -n "$version" ]] || {
  echo "Usage: ./scripts/verify-manifests.sh <image-name> <major.minor.patch>" >&2
  exit 2
}

[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Version must be major.minor.patch, got: ${version}" >&2
  exit 2
}

case "$image_name" in
  sec-forge|mesh-router|data-streams-producer|data-streams-consumer) ;;
  *)
    echo "Unknown image: ${image_name}" >&2
    exit 2
    ;;
esac

image_namespace="${IMAGE_NAMESPACE:-docker.io/cloudsprocket}"
max_attempts="${MANIFEST_VERIFY_ATTEMPTS:-6}"
retry_delay_seconds="${MANIFEST_VERIFY_RETRY_DELAY_SECONDS:-5}"

[[ "$max_attempts" =~ ^[1-9][0-9]*$ ]] || {
  echo "MANIFEST_VERIFY_ATTEMPTS must be a positive integer." >&2
  exit 2
}
[[ "$retry_delay_seconds" =~ ^[0-9]+$ ]] || {
  echo "MANIFEST_VERIFY_RETRY_DELAY_SECONDS must be a non-negative integer." >&2
  exit 2
}

inspect_manifest() {
  local reference="$1"
  local attempt=1
  local inspect_output=""
  local sleep_seconds

  while ! inspect_output="$(docker buildx imagetools inspect "$reference" 2>&1)"; do
    if ((attempt >= max_attempts)); then
      printf 'Unable to inspect %s after %d attempts.\n%s\n' \
        "$reference" "$max_attempts" "$inspect_output" >&2
      return 1
    fi

    sleep_seconds=$((retry_delay_seconds * attempt))
    printf 'Manifest %s is not ready (attempt %d/%d); retrying in %d seconds.\n' \
      "$reference" "$attempt" "$max_attempts" "$sleep_seconds" >&2
    sleep "$sleep_seconds"
    ((attempt += 1))
  done

  printf '%s\n' "$inspect_output"
}

image="${image_namespace}/${image_name}"
release_reference="${image}:${version}"
inspect_output="$(inspect_manifest "$release_reference")"
grep -q 'Platform:.*linux/amd64' <<<"$inspect_output" || {
  echo "Missing linux/amd64 manifest for ${release_reference}" >&2
  exit 1
}
grep -q 'Platform:.*linux/arm64' <<<"$inspect_output" || {
  echo "Missing linux/arm64 manifest for ${release_reference}" >&2
  exit 1
}

latest_output="$(inspect_manifest "${image}:latest")"
latest_digest="$(awk '/^Digest:/ {print $2; exit}' <<<"$latest_output")"
release_digest="$(awk '/^Digest:/ {print $2; exit}' <<<"$inspect_output")"
[[ -n "$latest_digest" && -n "$release_digest" ]] || {
  echo "Unable to resolve latest and release digests for ${image_name}" >&2
  exit 1
}
[[ "$latest_digest" == "$release_digest" ]] || {
  echo "Latest and release tags differ for ${image_name}" >&2
  echo "  latest:  ${latest_digest}" >&2
  echo "  ${version}: ${release_digest}" >&2
  exit 1
}

echo "Release manifests verified for ${image_name} ${version} (shared digest ${release_digest})."
