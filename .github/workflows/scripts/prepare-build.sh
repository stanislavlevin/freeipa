#!/bin/bash -eu

source "${IPA_TESTS_SCRIPTS}/variables-ci.sh"

function prepare_build() { :; }

# override prepare_build for the platform specifics
source "${IPA_TESTS_SCRIPTS}/prepare-build-${IPA_PLATFORM}.sh"

prepare_build
