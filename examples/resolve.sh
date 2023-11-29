#!/bin/bash

set -e -x

for d in $(find . -name apko.yaml); do
  (
    cd $(dirname ${d})
    docker run -v "$PWD":/work cgr.dev/chainguard/apko@sha256:d5e219c1ceb2e7d56a5933df54819467e5b3331098ea8bebc996fdd30f974f33 resolve /work/apko.yaml
  )
done
