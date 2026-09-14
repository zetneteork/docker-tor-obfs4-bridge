# docker-tor-obfs4-bridge

[![Lint & Test](https://github.com/zetneteork/docker-tor-obfs4-bridge/actions/workflows/ci.yml/badge.svg)](https://github.com/zetneteork/docker-tor-obfs4-bridge/actions/workflows/ci.yml)
[![Build & Release](https://github.com/zetneteork/docker-tor-obfs4-bridge/actions/workflows/docker-build-and-release.yml/badge.svg)](https://github.com/zetneteork/docker-tor-obfs4-bridge/actions/workflows/docker-build-and-release.yml)
[![Docker Hub](https://img.shields.io/docker/v/zetneteork/tor-obfs4-bridge?label=Docker%20Hub&sort=semver)](https://hub.docker.com/r/zetneteork/tor-obfs4-bridge)
[![GHCR](https://img.shields.io/badge/GHCR-ghcr.io%2Fzetneteork-blue)](https://github.com/zetneteork/docker-tor-obfs4-bridge/pkgs/container/docker-tor-obfs4-bridge)

A **multi-arch Docker image** (`amd64`, `arm64`, `armhf`) for running a
[Tor](https://www.torproject.org/) bridge with the
[obfs4](https://gitlab.com/yawning/obfs4) pluggable transport.

Bridges help censored users reach the Tor network by disguising traffic as
ordinary HTTPS. Running one is safe, legal in most jurisdictions, and only
requires two open TCP ports.

---

## Table of contents

- [Architecture](#architecture)
- [Quick start](#quick-start)
  - [Docker](#docker)
  - [Docker Compose](#docker-compose)
  - [Make](#make)
- [Environment variables](#environment-variables)
- [Getting your bridge line](#getting-your-bridge-line)
- [Kubernetes](#kubernetes)
  - [kustomize (recommended)](#kustomize-recommended)
  - [Single-file manifest](#single-file-manifest)
- [Helm chart](#helm-chart)
- [Persistent data](#persistent-data)
- [Versioning & releases](#versioning--releases)
- [CI/CD](#cicd)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

---

## Architecture

```
Internet
  │
  ├─► OR_PORT  (TCP, e.g. 2123) ──► Tor OR listener
  └─► PT_PORT  (TCP, e.g. 2133) ──► obfs4proxy ──► Tor ExtOR port
                                                       │
                                              /var/lib/tor  (persistent)
                                              /var/log/tor  (ephemeral)
```

- Base image: `debian:stable-slim`
- Tor source: [deb.torproject.org](https://deb.torproject.org) (official Tor Project repository)
- `obfs4proxy` from Debian backports
- Runs as `debian-tor` (uid=100, gid=101) — never root
- `obfs4proxy` is granted `cap_net_bind_service` so it can bind to ports < 1024

---

## Quick start

### Docker

```bash
docker run -d \
  --name tor-bridge \
  --restart unless-stopped \
  -p 2123:2123 \
  -p 2133:2133 \
  -v tor-datadir:/var/lib/tor \
  -e OR_PORT=2123 \
  -e PT_PORT=2133 \
  -e EMAIL=you@example.org \
  -e TOR_OR_PORT_IPV4=1 \
  -e TOR_EXITRELAY=0 \
  -e TOR_BRIDGERELAY=1 \
  ghcr.io/zetneteork/docker-tor-obfs4-bridge:latest
```

> **Firewall:** open TCP ports `OR_PORT` and `PT_PORT` inbound.

### Docker Compose

1. Copy `.env.example` to `.env` and fill in your values.
2. Run:

```bash
docker compose up -d
```

### Make

```bash
# Copy and edit default values
cp export.sh .env
$EDITOR .env

# Build and run locally
make build
OR_PORT=2123 PT_PORT=2133 EMAIL=you@example.org \
  TOR_OR_PORT_IPV4=1 TOR_EXITRELAY=0 TOR_BRIDGERELAY=1 \
  make deploy
```

---

## Environment variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `OR_PORT` | yes | – | TCP port for the Tor OR listener. Must be reachable from the internet. |
| `PT_PORT` | yes | – | TCP port for the obfs4 pluggable transport. Must be reachable from the internet. |
| `EMAIL` | yes | – | Operator contact address. Published in Tor's relay descriptor. |
| `TOR_OR_PORT_IPV4` | yes | – | `1` = restrict OR port to IPv4 only. `0` = dual-stack. |
| `TOR_EXITRELAY` | yes | – | `1` = enable exit relay. `0` = disabled (bridge-only). |
| `TOR_BRIDGERELAY` | yes | – | `1` = enable bridge relay mode. `0` = disabled. |

All six variables are required. `start-tor.sh` will exit with a clear error
message listing any that are missing.

---

## Getting your bridge line

After the container has been running for a few minutes and has bootstrapped
(look for `Bootstrapped 100%` in the logs):

```bash
# Docker
docker exec tor-bridge get-bridge-line

# Kubernetes
kubectl exec -n tor deploy/tor-obfs4-bridge -- get-bridge-line
```

The output will look like:

```
obfs4 203.0.113.42:2133 FINGERPRINT cert=xxxx iat-mode=0
```

Share this line with censored users or submit it to
[bridges.torproject.org](https://bridges.torproject.org/submit).

---

## Kubernetes

### kustomize (recommended)

The `k8s/` directory contains a production-grade kustomize layout with:

- Non-root security context (`runAsUser: 100`, `runAsGroup: 101`, `fsGroup: 101`)
- `capabilities: drop [ALL] add [NET_BIND_SERVICE]`
- `seccompProfile: RuntimeDefault`
- Resource requests/limits
- Liveness and readiness probes
- `EMAIL` loaded from a Kubernetes Secret

```bash
# 1. Create the namespace and secret
kubectl create namespace tor
kubectl create secret generic tor-config \
  --namespace tor \
  --from-literal=email=you@example.org

# 2. Review and edit the overlay
vim k8s/overlays/example/kustomization.yaml

# 3. Apply
kubectl apply -k k8s/overlays/example/

# 4. Watch bootstrap
kubectl logs -n tor -l app.kubernetes.io/name=tor-obfs4-bridge -f
```

### Single-file manifest

For quick trials (less secure — EMAIL is in plain text):

```bash
kubectl apply -f kube-deployment.yml
```

---

## Helm chart

A production Helm chart is available in the
[opentreecz/helm](https://github.com/opentreecz/helm) repository:

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update
helm install my-bridge opentree/tor-obfs4-bridge \
  --set config.email=you@example.org \
  --set service.orPort=2123 \
  --set service.ptPort=2133
```

See the [chart README](https://github.com/opentreecz/helm/tree/main/charts/tor-obfs4-bridge)
for all configurable values.

---

## Persistent data

Tor stores its long-term identity keys, cached descriptors, and obfs4 state
in `/var/lib/tor`. Mount a persistent volume there so the bridge keeps its
identity across restarts.

**Losing this data means your bridge gets a new fingerprint and must
re-bootstrap from scratch** — users will need a new bridge line.

---

## Versioning & releases

The image version follows the **Tor Debian package version**, e.g.:

```
0.4.9.12-1-d13.trixie-1
│         │   └── Debian release (trixie = Debian 13)
│         └────── Debian revision
└──────────────── Tor upstream version
```

Releases are **fully automated**:

1. Every push to `main` (and weekly on Monday) the CI builds an `amd64` image and
   reads the Tor version from the installed package.
2. If no GitHub release exists for that version yet, it builds and pushes the
   multi-arch image to **GHCR** and **Docker Hub**, then:
   - Updates the version string in `export.sh`, `docker-compose.yml`,
     and `kube-deployment.yml`.
   - Commits the bump as `<version>` on `main`.
   - Creates a GitHub release.

Manual intervention is only needed when changing the Dockerfile or scripts.

---

## CI/CD

| Workflow | Trigger | What it does |
|---|---|---|
| **Lint & Test** | PR / push to non-main | shellcheck, hadolint, unit tests, bats tests, container smoke test |
| **Build & Release** | Push to `main` / weekly | detect Tor version, build multi-arch, push GHCR + Docker Hub, bump files, cut release |
| **Dependabot** | Weekly (Monday) | PRs to update GitHub Actions and Docker base image |

### Required secrets (repository secrets, not environment secrets)

| Secret | Used for |
|---|---|
| `DOCKERHUB_USERNAME` | Authenticating to Docker Hub for push |
| `DOCKERHUB_TOKEN` | Docker Hub access token (not your password) |

`GHCR` uses the built-in `GITHUB_TOKEN` — no extra secret needed.

---

## Troubleshooting

**Container exits immediately**
- Check `docker logs tor-bridge` for the error.
- Most likely cause: a required environment variable is not set.

**Kubernetes: `/etc/tor/torrc: Permission denied`**
- This means the pod is running as the wrong UID. In the image, `debian-tor`
  is **uid=100, gid=101**. If your manifest or Helm chart sets `runAsUser: 101`
  (a common mistake — 101 is the gid, not the uid), the process cannot write
  `/etc/tor/torrc` which is owned by uid 100.
- **Fix:** ensure your `podSecurityContext` uses `runAsUser: 100`, `runAsGroup: 101`,
  `fsGroup: 101`. The kustomize manifests and Helm chart in this repository
  already use the correct values.
- Verify with: `docker run --rm --entrypoint sh <image> -c 'id debian-tor'`
  — you should see `uid=100(debian-tor) gid=101(debian-tor)`.

**`Bootstrapped 0%` stays there for > 5 minutes**
- Verify ports `OR_PORT` and `PT_PORT` are open inbound in your firewall/cloud security group.
- Try `TOR_OR_PORT_IPV4=1` if you're on an IPv4-only network.

**`get-bridge-line` says "fields missing"**
- Tor has not finished bootstrapping yet. Wait for `Bootstrapped 100%` in the logs.

**Old bridge line stops working**
- The data directory was lost. Users need the new bridge line from `get-bridge-line`.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Security

See [SECURITY.md](SECURITY.md) for the vulnerability reporting process.

---

## License

[MIT](LICENSE)
