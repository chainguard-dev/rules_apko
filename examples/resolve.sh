#!/bin/bash

set -e -x

find . -name apko.yaml | xargs bazel run @rules_apko//apko resolve