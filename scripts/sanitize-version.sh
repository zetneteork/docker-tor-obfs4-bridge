#!/usr/bin/env bash
# Sanitizes a Debian package version string (e.g. from `dpkg -s tor`) into a
# valid git tag / Docker image tag. Debian versions may contain characters
# such as : ~ + (epoch, pre-release, build metadata) that neither format
# allows.
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <raw-version>" >&2
    exit 1
fi

echo "$1" | sed -E 's/[^A-Za-z0-9._-]+/-/g; s/^[.-]+//; s/[.-]+$//'
