#
# Copyright (C) 2021  FreeIPA Contributors. See COPYING for license
#

"""Expose locally remote ipaplatform"""

from collections.abc import Mapping
from pathlib import Path
import base64
import json


def load(host, code_filename, func_name="main"):
    code_path = Path(__file__).parent / code_filename
    code = code_path.read_text(encoding="utf-8")
    code += f"\n{func_name}()"
    cmd = ["python3", "-c", code]
    res = host.run_command(cmd, log_stdout=False)
    return base64.b64decode(res.stdout_bytes).decode("utf-8")


class HostPlatformNameSpace(Mapping):
    def __init__(self, d):
        self._d = d

    def __getitem__(self, key):
        return self._d[key]

    def __iter__(self):
        return iter(self._d)

    def __len__(self):
        return len(self._d)

    def __getattr__(self, name):
        try:
            return self._d[name]
        except KeyError:
            raise AttributeError(name)


class HostPlatformPaths(HostPlatformNameSpace):
    def __init__(self, host):
        json_data = load(host, code_filename="_paths.py")
        super().__init__(
            json.loads(
                json_data, object_hook=lambda x: HostPlatformNameSpace(x)
            )
        )


class HostPlatformOSInfo(HostPlatformNameSpace):
    def __init__(self, host):
        json_data = load(host, code_filename="_osinfo.py")
        super().__init__(
            json.loads(
                json_data, object_hook=lambda x: HostPlatformNameSpace(x)
            )
        )


class HostPlatformConstants(HostPlatformNameSpace):
    def __init__(self, host):
        json_data = load(host, code_filename="_constants.py")
        super().__init__(
            json.loads(
                json_data, object_hook=lambda x: HostPlatformNameSpace(x)
            )
        )


class HostPlatformKnownservices(HostPlatformNameSpace):
    def __init__(self, host):
        json_data = load(host, code_filename="_knownservices.py")
        super().__init__(
            json.loads(
                json_data, object_hook=lambda x: HostPlatformNameSpace(x)
            )
        )


class HostPlatformTasks:
    def __init__(self, host):
        self.host = host
        self._pkcs11_modules = None

    @property
    def pkcs11_modules(self):
        if self._pkcs11_modules is None:
            json_data = load(
                self.host, code_filename="_tasks.py", func_name="pkcs11_modules"
            )
            self._pkcs11_modules = json.loads(json_data)

        return self._pkcs11_modules
