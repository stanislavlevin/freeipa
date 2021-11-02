#!/bin/bash -eu

function distro_autoconf() {
    ./autogen.sh \
        --with-password-quality-lib=no \

}
