#!/bin/bash -eu

function prepare_build() {
    apt-repo add task 310394
    apt-get update
    apt-get install -y gear rpm-build rpm-build-python3
    runuser -u "$GHA_USER" -- gear-rpm -bs --nodeps \
        --define '_allow_undefined_macros 1' \
        --define "_srcrpmdir $(pwd)" \
        --with "wheels" \
        --with "docs" \
        &&
        rpm -qp freeipa-*.src.rpm --requires |
        grep -v '^rpmlib(' |
        tr -d [[:blank:]] |
        tr '\n' ' ' |
        xargs sudo apt-get install -y
}
