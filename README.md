# docker-tor-obfs4-bridge
docker-obfs4-bridge tor brigde container

## Git repository:

https://github.com/zetneteork/docker-tor-obfs4-bridge

## Container images:

Multi-arch images (amd64, arm64, armhf) are built and published automatically
by [.github/workflows/docker-build-and-release.yml](.github/workflows/docker-build-and-release.yml)
whenever the upstream Tor Debian package version changes (checked on every
push to `main` and weekly). Each release is tagged with the Tor package
version (e.g. `0.4.8.17-2`), and `export.sh`, `docker-compose.yml` and
`kube-deployment.yml` are bumped to match automatically.

- Docker Hub: https://hub.docker.com/repository/docker/zetneteork/tor-obfs4-bridge
- GHCR: https://github.com/zetneteork/docker-tor-obfs4-bridge/pkgs/container/docker-tor-obfs4-bridge
