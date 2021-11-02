#!/bin/bash -eu

function build_docs() {
    export SPHINXBUILD=/usr/bin/sphinx-build-3
    make -C doc/ html
}
