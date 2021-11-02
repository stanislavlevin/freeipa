#!/bin/bash -eu

function run_tox() {
    tox.py3 -e py3,pypi,pylint3 -vv
}
