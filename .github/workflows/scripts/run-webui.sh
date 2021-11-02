#!/bin/bash -eu

source "${IPA_TESTS_SCRIPTS}/variables-ci.sh"

function run_webui() {
    # PhantomJS is not compatible with OpenSSL 1.1.1
    # https://github.com/wch/webshot/pull/93
    export OPENSSL_CONF=whatever
    cd "$GITHUB_WORKSPACE/install/ui/js/libs" && make
    cd "$GITHUB_WORKSPACE/install/ui" && npm install
    cd "$GITHUB_WORKSPACE/install/ui" &&
        node_modules/grunt/bin/grunt --verbose test
}

# override for the platform specifics
platform_script="${IPA_TESTS_SCRIPTS}/run-webui-${IPA_PLATFORM}.sh"
test -f "$platform_script" && source "$platform_script"

run_webui
