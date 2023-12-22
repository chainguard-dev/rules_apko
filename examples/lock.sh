#!/bin/bash

# Resolves all targets in the examples.

set -e -x

TARGETS=$(bazel query 'filter(".lock", kind("apko_run", ...))')
for target in ${TARGETS}; do 
  bazel run "${target}"
done

