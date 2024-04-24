#!/bin/bash 

# This file is used by https://github.com/bazel-contrib/.github/blob/master/.github/workflows/bazel.yaml

# We don't check correctness of the lock generation here, but that the target exists and runs successfully.
bazel run //:image_from_config_with_extra_files.lock