#!/usr/bin/env bash
# Decides whether the release workflow should (re)publish images and/or cut
# a new GitHub release, given whether a release already exists for this
# version and whether image-affecting files changed since it was made.
#
# Usage: release-plan.sh <release_exists: true|false> <code_changed: true|false>
# Prints two lines to stdout: "should_publish=<true|false>" and
# "should_release=<true|false>".
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <release_exists> <code_changed>" >&2
    exit 1
fi

release_exists="$1"
code_changed="$2"

if [ "$release_exists" = "false" ]; then
    should_publish=true
    should_release=true
elif [ "$code_changed" = "true" ]; then
    should_publish=true
    should_release=false
else
    should_publish=false
    should_release=false
fi

echo "should_publish=$should_publish"
echo "should_release=$should_release"
