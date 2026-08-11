#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

IMAGES=(sec-forge mesh-router data-streams-producer data-streams-consumer)

docker buildx bake -f docker-bake.hcl --check --set '*.platform=linux/amd64'

mapfile -t shell_files < <(
  find images scripts -type f \( -name '*.sh' -o -name '*.bash' \) -print | sort
)
for shell_file in "${shell_files[@]}"; do
  bash -n "$shell_file"
done

if command -v shellcheck >/dev/null 2>&1; then
  if ((${#shell_files[@]} > 0)); then
    shellcheck "${shell_files[@]}"
  fi
fi

if command -v hadolint >/dev/null 2>&1; then
  for image in "${IMAGES[@]}"; do
    hadolint "images/${image}/Dockerfile"
  done
fi

if command -v yamllint >/dev/null 2>&1; then
  yamllint -c .yamllint.yml .github examples images/mesh-router/examples .yamllint.yml
fi

for image in "${IMAGES[@]}"; do
  version_file="images/${image}/VERSION"
  [[ -f "$version_file" ]] || {
    echo "Missing ${version_file}" >&2
    exit 1
  }
  version="$(< "$version_file")"
  version="${version//$'\r'/}"
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
    echo "${version_file} must contain a semantic major.minor.patch value." >&2
    exit 1
  }
done

if [[ -f VERSION ]]; then
  echo "Root VERSION must not exist; images version independently." >&2
  exit 1
fi

if command -v rg >/dev/null 2>&1; then
  if rg -n --hidden --glob '!.git/**' --glob '!.local/**' \
    'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY' .; then
    echo "Private key material found." >&2
    exit 1
  fi

  if rg -n '^\s*uses:\s*[^@[:space:]]+@[^#[:space:]]+' .github/workflows \
    | grep -Ev '@[0-9a-f]{40}([[:space:]]|$)'; then
    echo "Every GitHub Action must be pinned to a full commit SHA." >&2
    exit 1
  fi
fi

for image in "${IMAGES[@]}"; do
  for file in docker-bake.hcl Makefile scripts/smoke-test.sh \
    scripts/verify-manifests.sh scripts/update-dockerhub-metadata.ps1 \
    .github/workflows/ci.yml .github/workflows/release.yml; do
    if ! grep -Fq "$image" "$file"; then
      echo "Image '${image}' is missing from ${file}" >&2
      exit 1
    fi
  done
done

echo "Static checks passed."
