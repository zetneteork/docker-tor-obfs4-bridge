#!/usr/bin/env bats
# tests/k8s-manifests.bats – Static guards for Kubernetes manifest security settings.
#
# These tests verify that the raw Kubernetes manifests (kube-deployment.yml
# and k8s/base/deployment.yaml) use the correct UID/GID for debian-tor.
#
# Regression guard: the original bug was runAsUser: 101 in both manifests,
# while debian-tor is uid=100 in the actual Docker image.  This caused:
#   /usr/local/bin/start-tor.sh: /etc/tor/torrc: Permission denied
#
# No cluster required – these are pure grep/text checks that run in the
# bats-tests CI job alongside start-tor.bats and get-bridge-line.bats.

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
KUBE_MANIFEST="${REPO_ROOT}/kube-deployment.yml"
K8S_BASE="${REPO_ROOT}/k8s/base/deployment.yaml"

# ---------------------------------------------------------------------------
# kube-deployment.yml
# ---------------------------------------------------------------------------

@test "kube-deployment.yml: runAsUser is 100 (not 101)" {
    # Fail if the wrong UID 101 is present.
    run grep -c "runAsUser: 101" "${KUBE_MANIFEST}"
    [ "${output}" = "0" ]
}

@test "kube-deployment.yml: runAsUser is set to 100" {
    run grep -c "runAsUser: 100" "${KUBE_MANIFEST}"
    [ "${status}" -eq 0 ]
    [ "${output}" != "0" ]
}

@test "kube-deployment.yml: runAsGroup is 101 (debian-tor group)" {
    run grep -c "runAsGroup: 101" "${KUBE_MANIFEST}"
    [ "${status}" -eq 0 ]
    [ "${output}" != "0" ]
}

@test "kube-deployment.yml: fsGroup is 101" {
    run grep -c "fsGroup: 101" "${KUBE_MANIFEST}"
    [ "${status}" -eq 0 ]
    [ "${output}" != "0" ]
}

@test "kube-deployment.yml: runAsNonRoot is true" {
    run grep -c "runAsNonRoot: true" "${KUBE_MANIFEST}"
    [ "${status}" -eq 0 ]
    [ "${output}" != "0" ]
}

# ---------------------------------------------------------------------------
# k8s/base/deployment.yaml
# ---------------------------------------------------------------------------

@test "k8s/base/deployment.yaml: runAsUser is 100 (not 101)" {
    run grep -c "runAsUser: 101" "${K8S_BASE}"
    [ "${output}" = "0" ]
}

@test "k8s/base/deployment.yaml: runAsUser is set to 100" {
    run grep -c "runAsUser: 100" "${K8S_BASE}"
    [ "${status}" -eq 0 ]
    [ "${output}" != "0" ]
}

@test "k8s/base/deployment.yaml: runAsGroup is 101 (debian-tor group)" {
    run grep -c "runAsGroup: 101" "${K8S_BASE}"
    [ "${status}" -eq 0 ]
    [ "${output}" != "0" ]
}

@test "k8s/base/deployment.yaml: fsGroup is 101" {
    run grep -c "fsGroup: 101" "${K8S_BASE}"
    [ "${status}" -eq 0 ]
    [ "${output}" != "0" ]
}

@test "k8s/base/deployment.yaml: runAsNonRoot is true" {
    run grep -c "runAsNonRoot: true" "${K8S_BASE}"
    [ "${status}" -eq 0 ]
    [ "${output}" != "0" ]
}

# ---------------------------------------------------------------------------
# Cross-check: both manifests agree on the same UID
# ---------------------------------------------------------------------------

@test "both manifests use the same runAsUser value" {
    uid_kube=$(grep "runAsUser:" "${KUBE_MANIFEST}" | awk '{print $2}' | head -1)
    uid_base=$(grep "runAsUser:" "${K8S_BASE}" | awk '{print $2}' | head -1)
    [ "${uid_kube}" = "${uid_base}" ]
}

@test "both manifests use the same runAsGroup value" {
    gid_kube=$(grep "runAsGroup:" "${KUBE_MANIFEST}" | awk '{print $2}' | head -1)
    gid_base=$(grep "runAsGroup:" "${K8S_BASE}" | awk '{print $2}' | head -1)
    [ "${gid_kube}" = "${gid_base}" ]
}
