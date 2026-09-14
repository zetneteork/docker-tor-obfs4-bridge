#!/usr/bin/env bash
# export.sh – Local development defaults.
# Source this file before running docker_start.sh or make deploy.
#
# WARNING: Do NOT commit real email addresses or secrets here.
#          Copy to .env and edit – .env is gitignored.
export VERSION=0.4.9.12-1-d13.trixie-1
export OR_PORT=2123
export PT_PORT=2133
export EMAIL=tor@opentree.cz
export TOR_OR_PORT_IPV4=1
export TOR_EXITRELAY=0
export TOR_BRIDGERELAY=1
