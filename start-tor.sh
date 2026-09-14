#!/usr/bin/env bash
# start-tor.sh – Generate /etc/tor/torrc from environment variables and start Tor.
#
# Required environment variables:
#   OR_PORT          – TCP port for the OR listener (e.g. 2123)
#   PT_PORT          – TCP port for the obfs4 pluggable transport (e.g. 2133)
#   EMAIL            – Operator contact address (e.g. tor@example.org)
#   TOR_OR_PORT_IPV4 – Set to "1" to restrict ORPort to IPv4 only; "0" for dual-stack
#   TOR_EXITRELAY    – "1" to act as an exit relay; "0" to disable
#   TOR_BRIDGERELAY  – "1" to act as a bridge relay; "0" to disable
set -euo pipefail

# ---------------------------------------------------------------------------
# Validate required environment variables
# ---------------------------------------------------------------------------
missing=()
for var in OR_PORT PT_PORT EMAIL TOR_OR_PORT_IPV4 TOR_EXITRELAY TOR_BRIDGERELAY; do
    if [[ -z "${!var:-}" ]]; then
        missing+=("$var")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    printf 'start-tor.sh: required environment variable(s) not set: %s\n' \
        "${missing[*]}" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Resolve TOR_OR_PORT_IPV4 flag
# ---------------------------------------------------------------------------
if [[ "${TOR_OR_PORT_IPV4}" == "1" ]]; then
    ipv4_flag="IPv4Only"
else
    ipv4_flag=""
fi

# ---------------------------------------------------------------------------
# Print runtime info
# ---------------------------------------------------------------------------
TOR_VERSION=$(dpkg-query -W -f='${Version}' tor 2>/dev/null || echo "unknown")

printf 'start-tor.sh: TOR_VERSION=%s OR_PORT=%s PT_PORT=%s EMAIL=%s TOR_OR_PORT_IPV4=%s TOR_BRIDGERELAY=%s TOR_EXITRELAY=%s\n' \
    "${TOR_VERSION}" "${OR_PORT}" "${PT_PORT}" "${EMAIL}" \
    "${ipv4_flag:-dual-stack}" "${TOR_BRIDGERELAY}" "${TOR_EXITRELAY}"

# ---------------------------------------------------------------------------
# Generate /etc/tor/torrc
# ---------------------------------------------------------------------------
generate_torrc() {
    cat <<EOF
RunAsDaemon 0
# No open SOCKS port – this is a bridge/relay only.
SocksPort 0
BridgeRelay ${TOR_BRIDGERELAY}
ExitRelay ${TOR_EXITRELAY}
# Static nickname makes it easy to identify bridges built from this image.
Nickname DockerObfs4Bridge
Log notice file /var/log/tor/log
Log notice stdout
ServerTransportPlugin obfs4 exec /usr/bin/obfs4proxy
ExtORPort auto
DataDirectory /var/lib/tor

# OR port – optionally restricted to IPv4 only.
ORPort ${OR_PORT} ${ipv4_flag}

# obfs4 pluggable-transport listener.
ServerTransportListenAddr obfs4 0.0.0.0:${PT_PORT}

# Operator contact information.
ContactInfo ${EMAIL}
EOF
}

# TORRC_PATH can be overridden for testing (defaults to /etc/tor/torrc).
TORRC_FILE="${TORRC_PATH:-/etc/tor/torrc}"

generate_torrc > "${TORRC_FILE}"

printf 'start-tor.sh: %s written, starting tor.\n' "${TORRC_FILE}"
exec tor -f /etc/tor/torrc
