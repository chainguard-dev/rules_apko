#!/usr/bin/env bash
# Checks that apko_lock_test targets fail, with an actionable message, when the
# lock file cannot be trusted. Usage:
#   apko_lock_test_failure_test.sh <stale lock test> <lock without checksum test>

set -uo pipefail

expect_failure() {
    local test_binary="$1"
    shift
    local output
    if output="$("$test_binary" 2>&1)"; then
        echo "FAIL: $test_binary passed, but was expected to fail." >&2
        exit 1
    fi
    for expected in "$@"; do
        if [[ "$output" != *"$expected"* ]]; then
            printf 'FAIL: output of %s does not contain "%s":\n%s\n' "$test_binary" "$expected" "$output" >&2
            exit 1
        fi
    done
}

expect_failure "$1" \
    "apko/tests/testdata/stale.apko.lock.json is out of date with apko/tests/config" \
    "Regenerate the lock file with \`bazel run //apko/tests:stale_lock\`."
expect_failure "$2" \
    "apko/tests/testdata/no_checksum.apko.lock.json does not record the checksum of its config"
