#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

external_apko=$(bazel cquery @rules_apko//apko:resolved_toolchain --output=files)
output_base=$(bazel info output_base)
apko="$output_base/$external_apko"


for yaml in "./examples/"*"/apko.yaml" "./e2e/"*"/apko.yaml"; do
  $apko lock $yaml
done

