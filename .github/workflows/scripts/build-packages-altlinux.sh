#!/bin/bash -eu

function build_packages() {
    gear-rpm -ba -v \
        --define "_topdir $GITHUB_WORKSPACE/rpmbuild" \
        --without 'lint' \
        --without 'fasttest'
    mkdir -p "$GITHUB_WORKSPACE"/dist/{,s}rpms
    mkdir -p "$GITHUB_WORKSPACE/dist/rpms_debuginfo"
    cp -v "$GITHUB_WORKSPACE"/rpmbuild/SRPMS/freeipa-*.src.rpm "$GITHUB_WORKSPACE/dist/srpms/"
    find "$GITHUB_WORKSPACE/rpmbuild/RPMS/" -type f \( -not -name "*-debuginfo-*" \
        -a -name '*.rpm' \) -exec cp {} "$GITHUB_WORKSPACE/dist/rpms/" \;
    find "$GITHUB_WORKSPACE/rpmbuild/RPMS/" -type f \( -name "*-debuginfo-*" \
        -a -name '*.rpm' \) -exec cp {} "$GITHUB_WORKSPACE/dist/rpms_debuginfo/" \;
}
