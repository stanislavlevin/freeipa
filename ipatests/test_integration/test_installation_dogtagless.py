"""
Tests for installations on Dogtag PKI less platforms.
"""

import pytest

from ipatests.pytest_ipa.integration import tasks
from ipatests.test_integration.base import IntegrationTest


class TestInstallWithCA_DogtagLess(IntegrationTest):
    @classmethod
    def install(cls, mh):
        result = cls.master.run_command(
            "python3 -c 'import importlib.util;"
            "print(int(importlib.util.find_spec(\"pki\") is not None))'"
        )
        if result.stdout_text.rstrip() == "1":
            raise pytest.fail("Requires uninstalled Dogtag PKI")

    @classmethod
    def uninstall(cls, mh):
        pass

    def test_ca_install_on_dogtag_less_host(self):
        result = tasks.install_master(self.master, raiseonerr=False)

        err_str = (
            "Dogtag PKI is unavailable on this platform, "
            "CA-less installation is the only supported."
        )
        assert result.returncode == 1
        assert err_str in result.stderr_text
