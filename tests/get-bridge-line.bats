#!/usr/bin/env bats
# tests/get-bridge-line.bats – Unit tests for get-bridge-line.
#
# The script's two inputs (TOR_LOG, PT_STATE) are overridden via environment
# variables to point at fixture files under tests/fixtures/.
#
# Run locally:
#   bats tests/get-bridge-line.bats

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
SCRIPT="${REPO_ROOT}/get-bridge-line"
FIXTURES="${REPO_ROOT}/tests/fixtures"

# Override the file paths used by get-bridge-line.
setup() {
    export TOR_LOG_PATH="${FIXTURES}/tor.log"
    export PT_STATE_PATH="${FIXTURES}/obfs4_bridgeline.txt"
}

# ---------------------------------------------------------------------------
# Success path
# ---------------------------------------------------------------------------

@test "outputs a valid bridge line from standard fixture" {
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    # Must start with 'obfs4'
    [[ "${output}" == obfs4\ * ]]
    # Must contain the fixture IP
    [[ "${output}" == *"203.0.113.42"* ]]
    # Must contain the fixture port
    [[ "${output}" == *":2133"* ]]
    # Must contain the fingerprint
    [[ "${output}" == *"AABBCCDDEEFF00112233445566778899AABBCCDD"* ]]
    # Must contain cert= fragment
    [[ "${output}" == *"cert="* ]]
    # Must contain iat-mode= fragment
    [[ "${output}" == *"iat-mode="* ]]
}

@test "resolves IP from fallback 'External address' log line" {
    export TOR_LOG_PATH="${FIXTURES}/tor-fallback-addr.log"
    run bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"198.51.100.7"* ]]
}

# ---------------------------------------------------------------------------
# Error paths – missing/unreadable inputs
# ---------------------------------------------------------------------------

@test "fails when TOR_LOG file does not exist" {
    export TOR_LOG_PATH="/nonexistent/tor.log"
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"cannot read"* ]]
}

@test "fails when PT_STATE file does not exist" {
    export PT_STATE_PATH="/nonexistent/obfs4_bridgeline.txt"
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"cannot read"* ]]
}

@test "fails when address cannot be parsed from log" {
    export TOR_LOG_PATH="${FIXTURES}/tor-no-addr.log"
    run bash "${SCRIPT}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"MISSING"* ]]
}
