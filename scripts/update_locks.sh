#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

external_apko=$(bazel cquery @rules_apko//apko:resolved_toolchain --output=files)
output_base=$(bazel info output_base)
apko="$output_base/$external_apko"


for yaml in "./examples/"*"/apko.yaml" "./e2e/"*"/apko.yaml"; do
  $apko lock $yaml
done

repo_root=$(pwd)

for workspace in "." "./e2e/smoke"; do
  cd $workspace
  for target in $(bazel query "kind(apko_lock, //...)"); do 
    echo $target
    #bazel run $target
  done
  cd $repo_root
done

