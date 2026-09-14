#!/usr/bin/env bats
# tests/start-tor.bats – Unit tests for start-tor.sh.
#
# These tests exercise the script without actually running Tor by stubbing
# the `tor` binary and `dpkg-query` with lightweight shell functions.
#
# Run locally:
#   bats tests/start-tor.bats
#
# In CI the `bats` job in .github/workflows/ci.yml installs bats-core
# and runs this file automatically.

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
START_TOR="${REPO_ROOT}/start-tor.sh"

# ---------------------------------------------------------------------------
# Helpers – fake out external commands
# ---------------------------------------------------------------------------
setup() {
    # Provide a stub tor binary that records its arguments.
    export BATS_TMPDIR
    stub_dir="$(mktemp -d)"
    export PATH="${stub_dir}:${PATH}"

    # Stub tor: just print a confirmation and exit 0.
    cat > "${stub_dir}/tor" <<'EOF'
#!/bin/sh
echo "STUB_TOR invoked: $*"
exit 0
EOF
    chmod +x "${stub_dir}/tor"

    # Stub dpkg-query: return a fixed version string.
    cat > "${stub_dir}/dpkg-query" <<'EOF'
#!/bin/sh
echo "0.4.9.12-1"
exit 0
EOF
    chmod +x "${stub_dir}/dpkg-query"

    export STUB_DIR="${stub_dir}"

    # Provide a writable /etc/tor/torrc target using a temp dir.
    TORRC_DIR="$(mktemp -d)"
    mkdir -p "${TORRC_DIR}/etc/tor"
    export TORRC_DIR

    # Redirect /etc/tor/torrc by bind-mounting via the stub: we can't mount
    # in a unit test, so instead we patch the script to write to a temp path.
    # Achieved by setting TORRC_PATH in the environment (start-tor.sh honours
    # it when set, falling back to /etc/tor/torrc).
    export TORRC_PATH="${TORRC_DIR}/etc/tor/torrc"
}

teardown() {
    rm -rf "${STUB_DIR}" "${TORRC_DIR}"
}

# Base set of valid env vars used by most tests.
base_env() {
    export OR_PORT=2123
    export PT_PORT=2133
    export EMAIL="tor@example.org"
    export TOR_OR_PORT_IPV4=0
    export TOR_EXITRELAY=0
    export TOR_BRIDGERELAY=1
}

# ---------------------------------------------------------------------------
# Env-var validation tests
# ---------------------------------------------------------------------------

@test "fails when OR_PORT is missing" {
    base_env
    unset OR_PORT
    run bash "${START_TOR}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"OR_PORT"* ]]
}

@test "fails when PT_PORT is missing" {
    base_env
    unset PT_PORT
    run bash "${START_TOR}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"PT_PORT"* ]]
}

@test "fails when EMAIL is missing" {
    base_env
    unset EMAIL
    run bash "${START_TOR}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"EMAIL"* ]]
}

@test "fails when TOR_OR_PORT_IPV4 is missing" {
    base_env
    unset TOR_OR_PORT_IPV4
    run bash "${START_TOR}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"TOR_OR_PORT_IPV4"* ]]
}

@test "fails when TOR_EXITRELAY is missing" {
    base_env
    unset TOR_EXITRELAY
    run bash "${START_TOR}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"TOR_EXITRELAY"* ]]
}

@test "fails when TOR_BRIDGERELAY is missing" {
    base_env
    unset TOR_BRIDGERELAY
    run bash "${START_TOR}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"TOR_BRIDGERELAY"* ]]
}

# ---------------------------------------------------------------------------
# torrc content tests (require writable TORRC_PATH)
# ---------------------------------------------------------------------------

@test "torrc contains ORPort with correct port" {
    base_env
    run bash "${START_TOR}"
    [ "${status}" -eq 0 ]
    grep -q "ORPort 2123" "${TORRC_PATH}"
}

@test "torrc contains ServerTransportListenAddr with PT_PORT" {
    base_env
    run bash "${START_TOR}"
    [ "${status}" -eq 0 ]
    grep -q "ServerTransportListenAddr obfs4 0.0.0.0:2133" "${TORRC_PATH}"
}

@test "torrc contains ContactInfo with EMAIL" {
    base_env
    run bash "${START_TOR}"
    [ "${status}" -eq 0 ]
    grep -q "ContactInfo tor@example.org" "${TORRC_PATH}"
}

@test "torrc contains BridgeRelay 1 when TOR_BRIDGERELAY=1" {
    base_env
    export TOR_BRIDGERELAY=1
    run bash "${START_TOR}"
    [ "${status}" -eq 0 ]
    grep -q "BridgeRelay 1" "${TORRC_PATH}"
}

@test "torrc contains ExitRelay 0 when TOR_EXITRELAY=0" {
    base_env
    export TOR_EXITRELAY=0
    run bash "${START_TOR}"
    [ "${status}" -eq 0 ]
    grep -q "ExitRelay 0" "${TORRC_PATH}"
}

@test "torrc contains Nickname DockerObfs4Bridge" {
    base_env
    run bash "${START_TOR}"
    [ "${status}" -eq 0 ]
    grep -q "Nickname DockerObfs4Bridge" "${TORRC_PATH}"
}

# ---------------------------------------------------------------------------
# TOR_OR_PORT_IPV4 branching
# ---------------------------------------------------------------------------

@test "ORPort line contains IPv4Only when TOR_OR_PORT_IPV4=1" {
    base_env
    export TOR_OR_PORT_IPV4=1
    run bash "${START_TOR}"
    [ "${status}" -eq 0 ]
    grep -q "ORPort 2123 IPv4Only" "${TORRC_PATH}"
}

@test "ORPort line has no IPv4Only suffix when TOR_OR_PORT_IPV4=0" {
    base_env
    export TOR_OR_PORT_IPV4=0
    run bash "${START_TOR}"
    [ "${status}" -eq 0 ]
    # The ORPort line should end with the port number, nothing else.
    grep -q "ORPort 2123 $\|ORPort 2123$" "${TORRC_PATH}"
}

# ---------------------------------------------------------------------------
# Tor invocation
# ---------------------------------------------------------------------------

@test "tor is invoked with -f /etc/tor/torrc" {
    base_env
    run bash "${START_TOR}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"STUB_TOR invoked: -f /etc/tor/torrc"* ]]
}
