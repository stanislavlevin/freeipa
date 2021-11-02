#!/bin/bash -eu

source "${IPA_TESTS_SCRIPTS}/variables-ci.sh"

function build_packages() { :; }

# override build_packages for the platform specifics
source "${IPA_TESTS_SCRIPTS}/build-packages-${IPA_PLATFORM}.sh"

build_packages
