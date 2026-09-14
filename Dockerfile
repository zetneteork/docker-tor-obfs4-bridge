# Base docker image
FROM debian:stable-slim

# OCI image labels – version/revision/created are injected by the CI build.
ARG IMAGE_VERSION=dev
ARG IMAGE_REVISION=unknown
ARG IMAGE_CREATED=unknown

LABEL org.opencontainers.image.title="tor-obfs4-bridge" \
      org.opencontainers.image.description="Tor obfs4 pluggable-transport bridge running on Debian stable-slim" \
      org.opencontainers.image.source="https://github.com/zetneteork/docker-tor-obfs4-bridge" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      maintainer="tor@opentree.cz"

# Install dependencies and configure Tor's apt repository.
RUN \
    . /etc/os-release && \
    apt update && \
    apt install -y \
        curl \
        gpg \
        gpg-agent \
        ca-certificates \
        libcap2-bin \
        --no-install-recommends && \
    # Add Tor Project GPG key to a dedicated keyring (modern, non-legacy method).
    # See: <https://support.torproject.org/apt/tor-deb-repo/>
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc \
        -o /etc/apt/keyrings/tor.asc && \
    printf 'deb [signed-by=/etc/apt/keyrings/tor.asc] https://deb.torproject.org/torproject.org %s main\n' \
        "${VERSION_CODENAME}" >> /etc/apt/sources.list.d/tor.list && \
    # Enable backports for obfs4proxy with correct codename (not a literal placeholder).
    printf 'Package: *\nPin: release a=%s-backports\nPin-Priority: 500\n' \
        "${VERSION_CODENAME}" > /etc/apt/preferences && \
    printf 'deb https://deb.debian.org/debian %s-backports main\n' \
        "${VERSION_CODENAME}" > /etc/apt/sources.list.d/backports.list && \
    apt update && \
    apt install -y \
        tor \
        tor-geoipdb \
        "obfs4proxy/${VERSION_CODENAME}" \
        --no-install-recommends && \
    echo "**** cleanup ****" && \
    apt clean && \
    rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/* && \
    # Allow obfs4proxy to bind to ports < 1024.
    setcap cap_net_bind_service=+ep /usr/bin/obfs4proxy && \
    # torrc is generated at run-time by start-tor.sh.
    rm /etc/tor/torrc && \
    chown debian-tor:debian-tor /etc/tor && \
    chown debian-tor:debian-tor /var/log/tor && \
    echo "install completed" && \
    dpkg-query -W -f='Version: ${Version}\n' tor

COPY start-tor.sh get-bridge-line /usr/local/bin/
RUN chmod 0755 /usr/local/bin/start-tor.sh /usr/local/bin/get-bridge-line

USER debian-tor

# Verify that Tor is alive and responding every 60 s; allow 2 min for initial bootstrap.
HEALTHCHECK --interval=60s --timeout=10s --start-period=120s --retries=3 \
    CMD pgrep -x tor > /dev/null || exit 1

CMD [ "/usr/local/bin/start-tor.sh" ]
