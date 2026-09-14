#!/usr/bin/env bash
# docker_start.sh – Launch the tor-obfs4-bridge container locally.
# Reads configuration from export.sh (or the environment if already set).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source export.sh only if it exists alongside this script.
if [[ -f "${SCRIPT_DIR}/export.sh" ]]; then
    # shellcheck source=export.sh
    . "${SCRIPT_DIR}/export.sh"
fi

# Validate that all required variables are present.
missing=()
for var in VERSION OR_PORT PT_PORT EMAIL TOR_OR_PORT_IPV4 TOR_EXITRELAY TOR_BRIDGERELAY; do
    if [[ -z "${!var:-}" ]]; then
        missing+=("$var")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    printf 'docker_start.sh: required variable(s) not set: %s\n' "${missing[*]}" >&2
    exit 1
fi

IMAGE="zetneteork/tor-obfs4-bridge:${VERSION}"

printf 'docker_start.sh: starting %s (OR_PORT=%s PT_PORT=%s)\n' \
    "${IMAGE}" "${OR_PORT}" "${PT_PORT}"

docker run -dit \
    --restart unless-stopped \
    -p "${OR_PORT}:${OR_PORT}" \
    -p "${PT_PORT}:${PT_PORT}" \
    --env OR_PORT="${OR_PORT}" \
    --env PT_PORT="${PT_PORT}" \
    --env EMAIL="${EMAIL}" \
    --env TOR_OR_PORT_IPV4="${TOR_OR_PORT_IPV4}" \
    --env TOR_EXITRELAY="${TOR_EXITRELAY}" \
    --env TOR_BRIDGERELAY="${TOR_BRIDGERELAY}" \
    --name tor \
    "${IMAGE}"
