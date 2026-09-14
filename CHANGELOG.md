# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions match the Tor Debian package version with an optional build suffix
(e.g. `0.4.9.12-1-d13.trixie-1`).

---

## [Unreleased]

### Added
- `.github/dependabot.yml` — weekly automated updates for GitHub Actions and
  the `debian:stable-slim` Docker base image.
- `tests/start-tor.bats` — bats unit tests for `start-tor.sh` covering env
  validation, torrc generation, and IPv4-only branching.
- `tests/get-bridge-line.bats` — bats unit tests for `get-bridge-line`
  covering the success path, fallback address detection, and all error paths.
- `tests/fixtures/` — sample Tor log and PT state files used by the tests.
- `bats-tests` job in `.github/workflows/ci.yml`.
- OCI image labels (`org.opencontainers.image.*`) injected via build args.
- `HEALTHCHECK` in Dockerfile (polls `pgrep -x tor`).
- `.dockerignore` — reduces build context size.
- `k8s/` kustomize layout (base + `overlays/example/`) as an alternative to
  the single-file manifest.
- `k8s/base/deployment.yaml` security hardening: non-root (`runAsUser: 101`),
  `capabilities drop ALL + NET_BIND_SERVICE`, `seccompProfile: RuntimeDefault`,
  resource requests/limits, liveness/readiness probes.
- `CONTRIBUTING.md`, `SECURITY.md`, `LICENSE`, `.editorconfig`, `.gitignore`.
- Expanded `README.md` with architecture diagram, env-var reference table,
  quickstart for Docker/Compose/make/k8s/Helm, troubleshooting guide.
- Helm chart in [opentreecz/helm](https://github.com/opentreecz/helm).

### Changed
- `start-tor.sh`: `set -euo pipefail`, up-front env validation with clear
  error messages, quoted variables, `exec tor` (avoids extra PID).
- `docker_start.sh`: `set -euo pipefail`, quoted variables, proper `source`.
- `get-bridge-line`: `set -euo pipefail`, improved error messages listing
  which field is missing, `TOR_LOG_PATH`/`PT_STATE_PATH` overridable for
  testing.
- `export.sh`: fixed typo `VESION` → `VERSION`; added inline comments.
- `Dockerfile`: `mkdir -p /etc/apt/keyrings` before `curl` (latent bug fix);
  fixed literal `<release>` apt pin placeholder to use `${VERSION_CODENAME}`;
  consolidated `COPY`+`chmod` into a single layer.
- `kube-deployment.yml`: hardened in-line with k8s base manifests; updated
  image reference to GHCR; added probes and resource limits.
- `Makefile`: added `lint`, `test`, `test-unit`, `test-bats`, `smoke`,
  `push-ghcr`, `push-dockerhub`, `helm-lint`, `help` targets.

### Fixed
- `export.sh`: typo `VESION` → `VERSION` (caused `docker_start.sh` to always
  use an empty image tag, pulling `image:` with no tag).
- Dockerfile apt-pin line used literal `<release>` placeholder instead of
  `${VERSION_CODENAME}` — backports pin was never applied correctly.
- `kube-deployment.yml` ran container as root (`runAsUser: 0`) despite the
  Dockerfile setting `USER debian-tor`.

---

## [0.4.9.12-1-d13.trixie-1] – 2024-01-08

### Changed
- Tor 0.4.9.12 from Debian trixie.
- Multi-arch image (amd64, arm64, armhf).
- Automated release workflow with GHCR + Docker Hub publishing.
- Migrated default branch from `master` to `main`.

## [0.4.9.11-1-d13.trixie-1] – 2023-11

### Changed
- Tor 0.4.9.11.

## [0.4.8.13-1] – 2023-08

### Changed
- Tor 0.4.8.13 from Debian bookworm.

## [0.4.8.10-1] – 2023

### Added
- Initial working image with obfs4proxy support.
- `docker-compose.yml`, `kube-deployment.yml`, `Makefile`.
