#!/bin/bash -eu

source "${IPA_TESTS_SCRIPTS}/variables-ci.sh"

function distro_autoconf() {
    ./autogen.sh
}

# override the platform specifics
platform_script="${IPA_TESTS_SCRIPTS}/autoconf-${IPA_PLATFORM}.sh"
test -f "$platform_script" && source "$platform_script"

distro_autoconf
