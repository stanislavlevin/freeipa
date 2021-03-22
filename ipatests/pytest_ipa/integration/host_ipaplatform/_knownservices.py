import base64
import json

from ipaplatform.services import knownservices


def main():
    remote_knownservices = {}
    for k,v in knownservices.items():
        remote_knownservices[k] = {}

        for name in sorted(dir(v)):
            if name.startswith("_"):
                continue

            value = getattr(v, name)
            try:
                json.dumps(value)
            except TypeError:
                continue

            remote_knownservices[k][name] = value

    json_data = json.dumps(remote_knownservices)
    json_base64 = base64.b64encode(
        json_data.encode("utf-8")
    ).decode("ascii")
    print(json_base64)
