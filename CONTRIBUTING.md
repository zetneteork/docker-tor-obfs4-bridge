# Contributing

Thank you for contributing to docker-tor-obfs4-bridge.

## Development setup

You need:
- Docker (with Buildx for multi-arch builds)
- `shellcheck`
- `bats` (bats-core) for shell unit tests
- `hadolint` (optional locally — runs in CI)
- `helm` (for Helm chart linting)

Install bats-core:

```bash
# Debian / Ubuntu
sudo apt-get install bats

# macOS
brew install bats-core
```

## Running checks locally

```bash
# Lint shell scripts and Dockerfile
make lint

# All tests (unit + bats)
make test

# Build image locally and run a smoke test
make smoke
```

## Making changes

1. Fork and branch from `main`.
2. Run `make lint test` before pushing.
3. Open a pull request against `main`.
4. The **Lint & Test** CI workflow runs automatically on all PRs.

## Dockerfile changes

When modifying the Dockerfile:
- Run `hadolint Dockerfile` locally (or let CI catch it).
- If the change affects the installed Tor version, a new release will be
  triggered automatically on merge.

## Shell script changes

All shell scripts must pass `shellcheck`. Run:

```bash
shellcheck start-tor.sh get-bridge-line docker_start.sh export.sh scripts/*.sh
```

Tests live in `tests/`:

| File | What it tests |
|---|---|
| `tests/start-tor.bats` | `start-tor.sh` env validation, torrc generation, IPv4 branching |
| `tests/get-bridge-line.bats` | `get-bridge-line` success + all error paths |
| `scripts/test-release-plan.sh` | `sanitize-version.sh` and `release-plan.sh` |

Add tests for any new behaviour before opening a PR.

## Versioning

Versions are derived from the Tor Debian package version and bumped
automatically by the release workflow. You do not need to edit version strings
by hand — see [README.md Versioning section](README.md#versioning--releases).

## Kubernetes / Helm

Changes to the kustomize layout (`k8s/`) should be tested with:

```bash
kubectl apply -k k8s/overlays/example/ --dry-run=client
```

Changes to the Helm chart live in the separate
[opentreecz/helm](https://github.com/opentreecz/helm) repository.
