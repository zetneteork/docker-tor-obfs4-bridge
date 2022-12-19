#!/bin/bash
. export.sh
docker run -dit --restart unless-stopped -p ${OR_PORT}:${OR_PORT} -p ${PT_PORT}:${PT_PORT} --env OR_PORT=${OR_PORT} --env PT_PORT=${PT_PORT} --env EMAIL=${EMAIL} --name tor zetneteork/tor-obfs4-bridge:${VERSION}

