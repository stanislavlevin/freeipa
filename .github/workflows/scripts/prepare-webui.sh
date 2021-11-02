#!/bin/bash -eu

source "${IPA_TESTS_SCRIPTS}/variables-ci.sh"

function prepare_webui() { :; }

# override prepare_webui for the platform specifics
source "${IPA_TESTS_SCRIPTS}/prepare-webui-${IPA_PLATFORM}.sh"

prepare_webui
