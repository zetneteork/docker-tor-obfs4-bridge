#!/usr/bin/env bats
# tests/image-permissions.bats – Container-level permission tests.
#
# These tests run against the built Docker image to verify that:
#   1. debian-tor has the correct uid=100 / gid=101 that the Kubernetes
#      manifests and Helm chart depend on (runAsUser: 100, runAsGroup: 101).
#   2. The container can write /etc/tor/torrc when running as the correct user.
#   3. No "Permission denied" errors occur when start-tor.sh runs.
#
# These tests require Docker to be available. They are executed in the
# build-smoke-test CI job against the locally built image
# (tor-obfs4-bridge:smoke-test). Set IMAGE env var to override:
#   IMAGE=tor-obfs4-bridge:smoke-test bats tests/image-permissions.bats
#
# Regression guard: the original bug was runAsUser: 101 in the Kubernetes
# manifests, while debian-tor is uid=100. This caused:
#   /usr/local/bin/start-tor.sh: line 13: /etc/tor/torrc: Permission denied
# because /etc/tor is owned by uid 100 (mode 755) and uid 101 cannot write it.

IMAGE="${IMAGE:-tor-obfs4-bridge:smoke-test}"

# ---------------------------------------------------------------------------
# Image identity tests
# ---------------------------------------------------------------------------

@test "debian-tor user has uid=100" {
    run docker run --rm --entrypoint sh "${IMAGE}" \
        -c "id -u debian-tor"
    [ "${status}" -eq 0 ]
    [ "${output}" = "100" ]
}

@test "debian-tor user has gid=101" {
    run docker run --rm --entrypoint sh "${IMAGE}" \
        -c "id -g debian-tor"
    [ "${status}" -eq 0 ]
    [ "${output}" = "101" ]
}

@test "container default user is uid=100 (debian-tor)" {
    run docker run --rm --entrypoint sh "${IMAGE}" \
        -c "id -u"
    [ "${status}" -eq 0 ]
    [ "${output}" = "100" ]
}

# ---------------------------------------------------------------------------
# Directory ownership tests
# /etc/tor, /var/lib/tor, /var/log/tor must all be owned by uid 100 so that
# the process running as uid 100 can read/write them.
# ---------------------------------------------------------------------------

@test "/etc/tor is owned by uid 100" {
    run docker run --rm --entrypoint sh "${IMAGE}" \
        -c "stat -c '%u' /etc/tor"
    [ "${status}" -eq 0 ]
    [ "${output}" = "100" ]
}

@test "/var/lib/tor is owned by uid 100" {
    run docker run --rm --entrypoint sh "${IMAGE}" \
        -c "stat -c '%u' /var/lib/tor"
    [ "${status}" -eq 0 ]
    [ "${output}" = "100" ]
}

@test "/var/log/tor is owned by uid 100" {
    run docker run --rm --entrypoint sh "${IMAGE}" \
        -c "stat -c '%u' /var/log/tor"
    [ "${status}" -eq 0 ]
    [ "${output}" = "100" ]
}

# ---------------------------------------------------------------------------
# Writability test – uid 100 can write /etc/tor (the torrc write)
# This directly reproduces the reported Kubernetes crash:
#   /etc/tor/torrc: Permission denied  (when running as uid 101)
# ---------------------------------------------------------------------------

@test "uid 100 can write a file to /etc/tor (torrc write succeeds)" {
    run docker run --rm --user 100:101 --entrypoint sh "${IMAGE}" \
        -c "echo 'test' > /etc/tor/torrc.test && echo 'write ok' && rm /etc/tor/torrc.test"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"write ok"* ]]
}

@test "uid 101 cannot write to /etc/tor (confirms the original bug)" {
    # This test documents the original failure mode:
    # running as uid 101 must NOT be able to write /etc/tor/torrc.
    run docker run --rm --user 101:101 --entrypoint sh "${IMAGE}" \
        -c "echo 'test' > /etc/tor/torrc.test 2>&1; echo exit:\$?"
    # The write should fail (non-zero exit from the subshell, or output
    # containing 'Permission denied' / non-zero exit code suffix).
    [[ "${output}" == *"Permission denied"* ]] || \
    [[ "${output}" == *"exit:1"* ]] || \
    [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# start-tor.sh smoke – no Permission denied when running as uid 100
# ---------------------------------------------------------------------------

@test "start-tor.sh produces no Permission denied when running as uid 100" {
    run docker run --rm --user 100:101 \
        -e OR_PORT=12345 \
        -e PT_PORT=12346 \
        -e EMAIL=test@example.com \
        -e TOR_OR_PORT_IPV4=1 \
        -e TOR_EXITRELAY=0 \
        -e TOR_BRIDGERELAY=1 \
        --entrypoint bash \
        "${IMAGE}" \
        -c "timeout 5 /usr/local/bin/start-tor.sh 2>&1 || true"
    [[ "${output}" != *"Permission denied"* ]]
}
