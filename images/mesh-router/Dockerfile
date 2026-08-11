# syntax=docker/dockerfile:1

# HAProxy 3.4 is the current LTS line; 3.4.3 verified on Docker Hub (2026-08-11).
FROM docker.io/library/haproxy:3.4.3

# Template used when BACKEND_SERVERS is supplied at runtime.
COPY haproxy.cfg.template /usr/local/etc/haproxy/haproxy.cfg.template

# Runtime entrypoint renders backends or accepts a full custom config.
USER root
COPY --chmod=0755 entrypoint.sh /usr/local/bin/mesh-router-entrypoint

# Official image already defines:
#   ENTRYPOINT ["docker-entrypoint.sh"]
#   CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
# We replace the entrypoint and drop a redundant CMD; our entrypoint chains
# to docker-entrypoint.sh and supplies the config path.
USER haproxy
ENTRYPOINT ["/usr/local/bin/mesh-router-entrypoint"]

EXPOSE 80 8404
