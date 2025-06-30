#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
RAW=$(mktemp)

REPOSITORY=${1:-"chainguard-dev/apko"}
TOOL=${2:-"apko"}

# per_page=1 to just mirror the most recent release
(
  curl --silent \
    --header "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/${REPOSITORY}/releases?per_page=1 \
    | jq -f "$SCRIPT_DIR/filter_${TOOL}.jq"
) > $RAW

FIXED=$(mktemp)
# Replace URLs with their hash
for tag in $(jq -r 'keys | .[]' < $RAW); do
  checksums="$(curl --silent --location https://github.com/${REPOSITORY}/releases/download/$tag/checksums.txt)"
  while read -r sha256 filename; do
    integrity="sha256-$(echo $sha256 | xxd -r -p | base64)"
    jq --indent 4 ".[\"$tag\"] |= with_entries(.value = (if .value == \"$filename\" then \"$integrity\" else .value end))" < $RAW > $FIXED
    mv $FIXED $RAW
  done <<< "$checksums"
done

cat >apko/private/versions.bzl <<EOF
"""Mirror of release info"""

# Add new versions by running
# ./scripts/mirror_apko.sh
EOF

echo -n "$(echo "$TOOL" | tr '[:lower:]' '[:upper:]')_VERSIONS = " >>apko/private/versions.bzl
cat $RAW | sed 's|"$|",|;s| }$| },|' >>apko/private/versions.bzl

sed "s|\"v0\.[0-9.]*\"|\"$tag\"|" -i MODULE.bazel apko/tests/versions_test.bzl
