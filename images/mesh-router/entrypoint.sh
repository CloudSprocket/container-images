#!/bin/sh
set -eu

TEMPLATE="/usr/local/etc/haproxy/haproxy.cfg.template"
RENDERED="/tmp/haproxy.cfg"
CUSTOM_CONFIG="${HAPROXY_CONFIG:-}"

render_from_backends() {
  servers="${BACKEND_SERVERS:-}"
  if [ -z "${servers}" ]; then
    echo "mesh-router: set BACKEND_SERVERS (comma-separated host:port list)" >&2
    echo "             or mount a full config and set HAPROXY_CONFIG" >&2
    exit 1
  fi

  if [ ! -f "${TEMPLATE}" ]; then
    echo "mesh-router: missing template ${TEMPLATE}" >&2
    exit 1
  fi

  # Build indented server lines from BACKEND_SERVERS.
  server_block=""
  index=1
  old_ifs=${IFS}
  IFS=','
  # shellcheck disable=SC2086
  set -- ${servers}
  IFS=${old_ifs}

  for entry in "$@"; do
    # Trim surrounding whitespace (POSIX parameter expansion).
    entry=${entry#"${entry%%[![:space:]]*}"}
    entry=${entry%"${entry##*[![:space:]]}"}
    if [ -z "${entry}" ]; then
      continue
    fi
    case "${entry}" in
      *:*)
        ;;
      *)
        echo "mesh-router: backend '${entry}' must be host:port" >&2
        exit 1
        ;;
    esac
    line="    server srv${index} ${entry} check inter 2000 rise 2 fall 3"
    if [ -z "${server_block}" ]; then
      server_block="${line}"
    else
      server_block="${server_block}
${line}"
    fi
    index=$((index + 1))
  done

  if [ "${index}" -eq 1 ]; then
    echo "mesh-router: BACKEND_SERVERS did not yield any backends" >&2
    exit 1
  fi

  # Substitute the placeholder with the generated server block.
  # Use a temp file and awk to preserve newlines safely.
  awk -v block="${server_block}" '
    {
      if (index($0, "__BACKEND_SERVERS__") > 0) {
        print block
      } else {
        print
      }
    }
  ' "${TEMPLATE}" > "${RENDERED}"
}

if [ -n "${CUSTOM_CONFIG}" ]; then
  if [ ! -f "${CUSTOM_CONFIG}" ]; then
    echo "mesh-router: HAPROXY_CONFIG='${CUSTOM_CONFIG}' not found" >&2
    exit 1
  fi
  CONFIG="${CUSTOM_CONFIG}"
else
  render_from_backends
  CONFIG="${RENDERED}"
fi

# Default to HAProxy with the resolved config when no arguments are given.
if [ "$#" -eq 0 ]; then
  set -- haproxy -f "${CONFIG}"
fi

# Chain through the official image entrypoint so -W -db flags stay applied.
exec docker-entrypoint.sh "$@"
