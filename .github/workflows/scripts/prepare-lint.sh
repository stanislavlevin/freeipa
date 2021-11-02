#!/bin/bash -eu

source "${IPA_TESTS_SCRIPTS}/variables-ci.sh"

function prepare_lint() { :; }

# override prepare_lint for the platform specifics
source "${IPA_TESTS_SCRIPTS}/prepare-lint-${IPA_PLATFORM}.sh"

prepare_lint
