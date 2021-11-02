#!/bin/bash -eu

source "${IPA_TESTS_SCRIPTS}/variables-ci.sh"

mkdir container
cp -pr dist container/
cp "$IPA_TESTS_DOCKERFILES/Dockerfile.build.$IPA_PLATFORM" container/Dockerfile
cd container
docker build -t "$IPA_DOCKER_IMAGE" .
docker save "$IPA_DOCKER_IMAGE" |
    gzip > "$GITHUB_WORKSPACE/$IPA_DOCKER_IMAGE-image.tar.gz"
