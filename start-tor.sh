#!/usr/bin/env bash

echo "Using OR_PORT=${OR_PORT}, PT_PORT=${PT_PORT}, and EMAIL=${EMAIL}."

cat > /etc/tor/torrc << EOF
RunAsDaemon 0
# We don't need an open SOCKS port.
SocksPort 0
BridgeRelay 1
# A static nickname makes it easy to identify bridges that were set up using
# this Docker image.
Nickname DockerObfs4Bridge
Log notice file /var/log/tor/log
Log notice stdout
ServerTransportPlugin obfs4 exec /usr/bin/obfs4proxy
ExtORPort auto
DataDirectory /var/lib/tor

# The variable "OR_PORT" is replaced with the OR port.
ORPort ${OR_PORT}

# The variable "PT_PORT" is replaced with the obfs4 port.
ServerTransportListenAddr obfs4 0.0.0.0:${PT_PORT}

# The variable "EMAIL" is replaced with the operator's email address.
ContactInfo ${EMAIL}
EOF

echo "Starting tor."
tor -f /etc/tor/torrc