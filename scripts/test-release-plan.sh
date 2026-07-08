#!/usr/bin/env bash
# Unit tests for sanitize-version.sh and release-plan.sh - the two pieces of
# logic in the release workflow that have already caused real CI failures
# (invalid tag characters, and permanently skipping publish after a partial
# failure). Run directly: bash scripts/test-release-plan.sh
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" != "$actual" ]; then
        echo "FAIL: $desc"
        echo "  expected: $(printf '%q' "$expected")"
        echo "  actual:   $(printf '%q' "$actual")"
        fail=1
    else
        echo "PASS: $desc"
    fi
}

# --- sanitize-version.sh ---

assert_eq "sanitize: Debian ~backport+buildinfo suffix" \
    "0.4.9.11-1-d13.trixie-1" \
    "$(scripts/sanitize-version.sh '0.4.9.11-1~d13.trixie+1')"

assert_eq "sanitize: plain version passes through unchanged" \
    "0.4.8.17-2" \
    "$(scripts/sanitize-version.sh '0.4.8.17-2')"

assert_eq "sanitize: Debian epoch colon" \
    "1-0.4.8.13-1" \
    "$(scripts/sanitize-version.sh '1:0.4.8.13-1')"

assert_eq "sanitize: strips leading/trailing separators after substitution" \
    "0.4.8.13-1" \
    "$(scripts/sanitize-version.sh '~0.4.8.13-1~')"

# --- release-plan.sh ---

assert_eq "plan: no release yet -> publish and release" \
    "$(printf 'should_publish=true\nshould_release=true')" \
    "$(scripts/release-plan.sh false false)"

assert_eq "plan: release exists, relevant files changed -> republish, no new release" \
    "$(printf 'should_publish=true\nshould_release=false')" \
    "$(scripts/release-plan.sh true true)"

assert_eq "plan: release exists, nothing changed -> skip entirely" \
    "$(printf 'should_publish=false\nshould_release=false')" \
    "$(scripts/release-plan.sh true false)"

if [ "$fail" -ne 0 ]; then
    echo
    echo "One or more tests FAILED"
    exit 1
fi

echo
echo "All tests passed"
