#!/bin/bash -eu

source "${IPA_TESTS_SCRIPTS}/variables-ci.sh"

function run_tox() {
    tox -e py3,pypi,pylint3 -vv
}

# override for the platform specifics
platform_script="${IPA_TESTS_SCRIPTS}/run-tox-${IPA_PLATFORM}.sh"
test -f "$platform_script" && source "$platform_script"

run_tox
