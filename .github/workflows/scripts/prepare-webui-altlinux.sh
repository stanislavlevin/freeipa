#!/bin/bash -eu

function prepare_webui() {
    apt-get -y install npm fontconfig \
        libatk \

}
