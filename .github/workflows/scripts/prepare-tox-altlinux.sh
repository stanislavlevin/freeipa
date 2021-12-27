#!/bin/bash -eu

function prepare_tox() {
    apt-get install -y nss-tools python3-module-pip
    runuser -u "$GHA_USER" -- \
        python3 -m pip install --user --upgrade pip pycodestyle
}
