#!/usr/bin/env bash

# Generated by apko_bazelrc. DO NOT EDIT
# Adds Range header to outgoing http requests by parsing the range fragment on URL from stdin
# See https://github.com/bazelbuild/proposals/blob/main/designs/2022-06-07-bazel-credential-helpers.md

# Required for range requests for fetching the apk packages.
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests

echo -n '{"headers":{"Range":['
cat | sed -n 's/.*#_apk_range_bytes_\([[:digit:]]*-[[:digit:]]*\).*/"bytes=\1"/p' | tr -d '\n'
echo ']}}'
