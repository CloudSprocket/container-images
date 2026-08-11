# syntax=docker/dockerfile:1

FROM docker.io/library/ubuntu:24.04

ARG TARGETARCH
ARG DEBIAN_FRONTEND=noninteractive

# Pinned tool versions (verified 2026-08-11; see image README for sources).
ARG TRIVY_VERSION=0.73.0
ARG GRYPE_VERSION=0.117.0
ARG SEMGREP_VERSION=1.172.0
ARG CHECKOV_VERSION=3.3.10

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/opt/tools/bin:${PATH} \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    LANG=C.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       gnupg \
       jq \
       python3 \
       python3-pip \
       python3-venv \
       unzip \
       wget \
    && rm -rf /var/lib/apt/lists/*

# Trivy: modern keyring + pinned package (replaces jammy suite and apt-key).
# Upstream publishes current debs only to the "generic" suite from v0.72.0
# onwards; per-codename suites (including noble) no longer receive new
# packages. See aquasecurity/trivy discussion #10819. "generic" is the
# correct suite on Ubuntu 24.04 (noble) for Trivy ${TRIVY_VERSION}.
RUN set -eux; \
    install -d -m 0755 /etc/apt/keyrings; \
    curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key \
      | gpg --dearmor -o /etc/apt/keyrings/trivy.gpg; \
    chmod 0644 /etc/apt/keyrings/trivy.gpg; \
    printf 'deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main\n' \
      > /etc/apt/sources.list.d/trivy.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends "trivy=${TRIVY_VERSION}"; \
    rm -rf /var/lib/apt/lists/*; \
    trivy --version

# Grype: pinned multi-arch release artefact with checksum verification.
# Replaces curl|sh from the live main branch.
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) \
        GRYPE_SHA256="38525dab1e06f162ebaa02f94d82d1f807076b011a44180cf2777edf1a7b9c26" \
        ;; \
      arm64) \
        GRYPE_SHA256="935f628bdf9331ffdd946931ea5fdb50045d3970ba52670cbeb44a88f127291b" \
        ;; \
      *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/grype.tar.gz \
      "https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_${TARGETARCH}.tar.gz"; \
    echo "${GRYPE_SHA256}  /tmp/grype.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/grype.tar.gz -C /usr/local/bin grype; \
    chmod 0755 /usr/local/bin/grype; \
    rm -f /tmp/grype.tar.gz; \
    grype version

# Semgrep and Checkov in an isolated venv with pinned versions.
RUN python3 -m venv /opt/tools \
    && /opt/tools/bin/pip install --no-cache-dir --no-compile \
       "semgrep==${SEMGREP_VERSION}" \
       "checkov==${CHECKOV_VERSION}" \
    && printf 'export PATH=/opt/tools/bin:$PATH\n' > /etc/profile.d/sec-forge.sh \
    && chmod 0644 /etc/profile.d/sec-forge.sh \
    && semgrep --version \
    && checkov --version

# Ubuntu 24.04 ships a default "ubuntu" account already holding uid/gid 1000,
# so creating scanner there collides unless that account is removed first.
# Keeping scanner on 1000 is deliberate: it is the usual first uid on a Linux
# host, so a bind mount is readable and writable without a --user override for
# most people. See this image's README for the cases where it is not.
RUN set -eux; \
    if id -u ubuntu >/dev/null 2>&1; then userdel --remove ubuntu; fi; \
    if getent group ubuntu >/dev/null 2>&1; then groupdel ubuntu; fi; \
    groupadd --gid 1000 scanner; \
    useradd --create-home --shell /bin/bash --uid 1000 --gid 1000 scanner; \
    mkdir -p /workspace; \
    chown scanner:scanner /workspace

USER scanner
WORKDIR /workspace

CMD ["/bin/bash"]
