#!/bin/bash -eu

function install_debuginfo() {
    # add debuginfo component
    sed -i 's/^\(rpm .*\)\(\/x86_64 classic\)$/\1\2 debuginfo/' /etc/apt/sources.list && \
    apt-repo add 'rpm-dir file:/rpms x86_64 local_debug_rpms' && \
    apt-repo && \
    apt-get update && \
    apt-get install -y \
        gdb \
        systemd-coredump \
        autofs-debuginfo \
        ${IPA_TESTS_REPO_PATH}/dist/rpms_debuginfo/*.rpm \
        389-ds-base-debuginfo \
        libjemalloc2-debuginfo \
        libsasl2-plugin-gssapi-debuginfo \
        slapi-nis-debuginfo \
        apache2-base-debuginfo \
        apache2-mod_auth_gssapi-debuginfo \
        apache2-mod_ssl-debuginfo \
        apache2-mod_wsgi-py3-debuginfo \
        apache2-mods-debuginfo \
        bind-debuginfo \
        bind-utils-debuginfo \
        bind-dyndb-ldap-debuginfo \
        libp11-debuginfo \
        certmonger-debuginfo \
        gssproxy-debuginfo \
        krb5-kdc-debuginfo \
        krb5-kinit-debuginfo \
        samba-dc-mitkrb5-debuginfo \
        sssd-debuginfo \
        sssd-idp-debuginfo
}
