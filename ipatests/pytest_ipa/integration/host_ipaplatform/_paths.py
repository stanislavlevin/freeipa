import base64
import json

from ipaplatform.paths import paths


def main():
    remote_paths = {}
    for name in sorted(dir(paths)):
        if name.startswith("_"):
            continue

        value = getattr(paths, name)
        try:
            json.dumps(value)
        except TypeError:
            continue

        remote_paths[name] = value

    json_data = json.dumps(remote_paths)
    json_base64 = base64.b64encode(
        json_data.encode("utf-8")
    ).decode("ascii")
    print(json_base64)
