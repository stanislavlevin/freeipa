import base64
import json

from ipaplatform.osinfo import osinfo


def main():
    remote_osinfo = {}
    for name in sorted(dir(osinfo)):
        if name.startswith("_"):
            continue

        value = getattr(osinfo, name)
        try:
            json.dumps(value)
        except TypeError:
            continue

        remote_osinfo[name] = value

    json_data = json.dumps(remote_osinfo)
    json_base64 = base64.b64encode(
        json_data.encode("utf-8")
    ).decode("ascii")
    print(json_base64)
