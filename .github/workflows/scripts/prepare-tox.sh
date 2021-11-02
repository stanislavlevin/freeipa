#!/bin/bash -eu

source "${IPA_TESTS_SCRIPTS}/variables-ci.sh"

function prepare_tox() { :; }

# override prepare_tox for the platform specifics
source "${IPA_TESTS_SCRIPTS}/prepare-tox-${IPA_PLATFORM}.sh"

prepare_tox
