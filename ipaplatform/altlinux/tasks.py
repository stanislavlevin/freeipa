#
# Copyright (C) 2018  FreeIPA Contributors see COPYING for license
#

"""
This module contains default ALT Linux specific implementations of system
tasks.
"""

from ipaplatform.redhat.tasks import RedHatTaskNamespace
from ipaplatform.paths import paths
from ipapython import directivesetter
from ipapython import ipautil
from ipapython.ipachangeconf import IPAChangeConf


class ALTLinuxTaskNamespace(RedHatTaskNamespace):
    def restore_pre_ipa_client_configuration(
        self, fstore, statestore, was_sssd_installed, was_sssd_configured
    ):
        """
        Restores the pre-ipa-client configuration that was modified by the
        following platform tasks:
            modify_nsswitch_pam_stack
        """
        if statestore.has_state("control"):
            value = statestore.restore_state("control", "system-auth")
            if value is not None:
                ipautil.run(["control", "system-auth", value])

    def set_nisdomain(self, nisdomain):
        return True

    def enable_nsswitch_automount(self, statestore):
        database = "automount"
        conf = IPAChangeConf("IPA automount installer")
        conf.setOptionAssignment(":")

        # Read the existing configuration
        with open(paths.NSSWITCH_CONF) as f:
            opts = conf.parse(f)

        raw_database_entry = conf.findOpts(opts, "option", database)[1]

        # Detect the list of already configured services
        if not raw_database_entry:
            # If there is no database entry, database is not present in
            # the nsswitch.conf
            configured_services = ["files"]
            statestore.backup_state("ipaclient_automount", "nss", "")
        else:
            configured_services = raw_database_entry["value"].strip().split()
            statestore.backup_state(
                "ipaclient_automount", "nss", " ".join(configured_services)
            )

        added_services = ["sss"]
        # drop already configured service if it matches
        configured_services = [
            s
            for s in configured_services
            if s not in added_services
        ]

        new_value = " " + " ".join(added_services + configured_services)

        # Set new services as sources for database
        opts = [conf.setOption(database, new_value)]

        conf.changeConf(paths.NSSWITCH_CONF, opts)

    def disable_nsswitch_automount(self, statestore):
        nss_state = statestore.get_state("ipaclient_automount", "nss")
        if nss_state is None:
            # nothing to do
            return

        conf = IPAChangeConf("IPA automount installer")
        conf.setOptionAssignment(":")
        if nss_state == "":
            opts = [conf.rmOption("automount")]
        else:
            opts = [conf.setOption("automount", " " + nss_state)]
        conf.changeConf(paths.NSSWITCH_CONF, opts)
        statestore.delete_state("ipaclient_automount", "nss")

    def modify_nsswitch_pam_stack(
        self, sssd, mkhomedir, fstore, statestore, sudo=True, subid=False
    ):
        """
        If sssd flag is true, configure pam and nsswitch so that SSSD is used
        for retrieving user information and authentication.

        This method provides functionality similar to the authselect tool:
        https://github.com/authselect/authselect/blob/master/profiles/sssd/nsswitch.conf

        shadow:     files
        passwd:     files sss
        group:      files sss
        services:   files sss
        netgroup:   files sss
        automount:  files sss
        sudoers:    files sss {include if "with-sudo"}
        subid:      sss {include if "with-subid"}

        Note: ALT's sssd is built with `--disable-files-domain`, so,
        passwd and group should be set to files as the first service.
        """
        if not sssd:
            return

        # Configure nsswitch.conf
        # unconditionally append 'sss'
        for database in (
            "passwd", "group", "netgroup", "automount", "services"
        ):
            self.configure_nsswitch_database(
                fstore,
                database,
                ["sss"],
                append=True,
                default_value=["files"],
            )

        if sudo:
            # usually no-op, since 'enable_sssd_sudo' was called earlier
            self.configure_nsswitch_database(
                fstore,
                "sudoers",
                ["sss"],
                append=True,
                default_value=["files"],
            )

        if subid:
            self.configure_nsswitch_database(
                fstore, "subid", ["sss"], preserve=False
            )

        # Configure PAM
        res = ipautil.run(["control", "system-auth"], capture_output=True)
        statestore.backup_state(
            "control", "system-auth", res.output.rstrip("\n")
        )
        ipautil.run(["control", "system-auth", "sss"])

    def modify_pam_to_use_krb5(self, statestore):
        return True

    def backup_auth_configuration(self, path):
        return True

    def restore_auth_configuration(self, path):
        return True

    def migrate_auth_configuration(self, statestore):
        return True

    def configure_httpd_protocol(self):
        # don't rely on SSL_PROTOCOL_DEFAULT,
        # which is set if SSLProtocol is not defined
        directivesetter.set_directive(
            paths.HTTPD_SSL_CONF,
            "SSLProtocol",
            "all -SSLv3 -TLSv1 -TLSv1.1",
            False,
        )


tasks = ALTLinuxTaskNamespace()
