# Base docker image
FROM debian:stable-slim

LABEL maintainer="tor@opentree.cz <tor@opentree.cz>"

# Install dependencies to add Tor's repository.
RUN \
    . /etc/os-release &&\
    apt-get update &&\
    apt-get install -y \
        curl \
        gpg \
        gpg-agent \
        ca-certificates \
        libcap2-bin \
        --no-install-recommends &&\
    # See: <https://2019.www.torproject.org/docs/debian.html.en>
    curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import &&\
    gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add - &&\
    printf "deb https://deb.torproject.org/torproject.org stable main\n" >> /etc/apt/sources.list.d/tor.list &&\
    printf "Package: *\nPin: release a=<release>-backports\nPin-Priority: 500\n" > /etc/apt/preferences &&\
    echo "deb https://deb.debian.org/debian ${VERSION_CODENAME}-backports main" > /etc/apt/sources.list.d/backports.list &&\
    apt-get update &&\
    apt-get install -y \
        tor \
        tor-geoipdb \
        obfs4proxy/${VERSION_CODENAME}-backports \
        --no-install-recommends &&\
    #apt-get dist-upgrade -qyf &&\
    echo "**** cleanup ****" && \
    apt-get clean && \
    rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/* &&\
    # Allow obfs4proxy to bind to ports < 1024.
    setcap cap_net_bind_service=+ep /usr/bin/obfs4proxy &&\
    # Our torrc is generated at run-time by the script start-tor.sh.
    rm /etc/tor/torrc &&\
    chown debian-tor:debian-tor /etc/tor &&\
    chown debian-tor:debian-tor /var/log/tor &&\
    echo "install completed" &&\
    dpkg -s tor | grep '^Version:'

    
COPY start-tor.sh /usr/local/bin
RUN chmod 0755 /usr/local/bin/start-tor.sh

COPY get-bridge-line /usr/local/bin
RUN chmod 0755 /usr/local/bin/get-bridge-line

USER debian-tor

CMD [ "/usr/local/bin/start-tor.sh" ]
