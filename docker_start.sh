#!/bin/bash
. export.sh
docker run -dit --restart unless-stopped \
    -p ${OR_PORT}:${OR_PORT} \
    -p ${PT_PORT}:${PT_PORT} \
    --env OR_PORT=${OR_PORT} \
    --env PT_PORT=${PT_PORT} \
    --env EMAIL=${EMAIL} \
    --env TOR_OR_PORT_IPV4=${TOR_OR_PORT_IPV4} \
    --env TOR_EXITRELAY=${TOR_EXITRELAY} \
    --env TOR_BRIDGERELAY=${TOR_BRIDGERELAY} \
    --name tor zetneteork/tor-obfs4-bridge:${VERSION}

