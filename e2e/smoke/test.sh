#!/bin/bash 

# This file is used by https://github.com/bazel-contrib/.github/blob/master/.github/workflows/bazel.yaml
# which is used in presubmit workflow https://github.com/chainguard-dev/rules_apko/blob/1d78765293a0baf3f92ca49efa51d6c02b9c828e/.github/workflows/ci.yaml#L20

# We don't check correctness of the lock generation here, but that the target exists and runs successfully.
bazel run //multifile_config:lock_from_generated_config
