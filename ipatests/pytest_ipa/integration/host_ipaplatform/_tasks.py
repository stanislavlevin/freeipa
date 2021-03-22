import base64
import json

from ipaplatform.tasks import tasks


def pkcs11_modules():
    pkcs11_modules = tasks.get_pkcs11_modules()
    json_data = json.dumps(pkcs11_modules)
    json_base64 = base64.b64encode(
        json_data.encode("utf-8")
    ).decode("ascii")
    print(json_base64)
