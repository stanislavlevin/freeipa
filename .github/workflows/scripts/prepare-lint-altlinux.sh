#!/bin/bash -eu

function prepare_lint() {
    apt-get -y install python3-module-pip
    runuser -u "$GHA_USER" -- \
        python3 -m pip install \
            --user \
            --constraint .wheelconstraints.in \
            --ignore-installed \
            pylint \

}
