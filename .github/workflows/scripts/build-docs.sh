#!/bin/bash -eu

source "${IPA_TESTS_SCRIPTS}/variables-ci.sh"

function build_docs() {
    echo "Generate virtual environment for building documentation"
    make -C doc/ venv
    echo "Build documentation"
    make -C doc/ html
}

# override for the platform specifics
platform_script="${IPA_TESTS_SCRIPTS}/build-docs-${IPA_PLATFORM}.sh"
test -f "$platform_script" && source "$platform_script"

build_docs
