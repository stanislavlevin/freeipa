import yaml

PRCI_NIGHTLY = "ipatests/prci_definitions/nightly_ipa-4-12_latest.yaml"
PRCI_GATING = "ipatests/prci_definitions/gating.yaml"
AZURE_NIGHTLY = "ipatests/azure/azure_definitions/nightly.yml"
AZURE_GATING = "ipatests/azure/azure_definitions/gating.yml"

prci_tests = []
azure_tests = []

SKIP_IN_AZURE_LIST = [
    "test_integration/test_advise.py",  # RHEL/Fedora specific
    "test_integration/test_authselect.py",  # ALT doesn't have authselect
    "test_integration/test_idviews",  # RunADTests class(2 IPA + 1 AD classes)
    "test_integration/test_fips.py",  # requires fake FIPS mode
    # requires AD
    "test_integration/test_http_kdc_proxy.py",
    "test_integration/test_replica_promotion.py::TestReplicaConn",
    # requires external DNS
    "test_integration/test_installation.py::TestADTrustInstall",
    "test_integration/test_installation.py::TestInstallWithoutNamed",
    "test_integration/test_random_serial_numbers.py::TestRSNPKIConfig",
    "test_integration/test_random_serial_numbers.py::TestInstallWithCA_KRA1_RSN",
    "test_integration/test_installation.py::TestInstallWithCA1",
    "test_integration/test_installation.py::TestInstallWithCA2",
    "test_integration/test_installation.py::TestInstallWithCA_KRA1",
    "test_integration/test_installation.py::TestInstallWithCA_KRA2",
]

EXTRA_AZURE_LIST = [
    "test_integration/test_idviews.py::TestRulesWithServicePrincipals",
    "test_integration/test_idviews.py::TestIDViews",
    # patched in ALT
    "test_integration/test_nfs.py::TestNFS",
    # ALT specific tests
    "test_integration/test_ntp_options.py::TestNTPMissingOptionsAndNTPs",
    "test_integration/test_ntp_options.py::TestNTPoptionsCommon",
]


def parse_prci_tests(config, tests):
    with open(config) as f:
        prci_yaml = yaml.safe_load(f)
        for task in prci_yaml["jobs"].values():
            job = task["job"]
            if job["class"] == "RunPytest":
                tests.extend(job["args"]["test_suite"].split())

    tests.sort()


def parse_azure_tests(config, tests):
    with open(config) as f:
        azure_yaml = yaml.safe_load(f)
        for vm_jobs in azure_yaml["vms"]:
            for job in vm_jobs["vm_jobs"]:
                tests.extend(job["tests"])

    tests.sort()


parse_prci_tests(PRCI_GATING, tests=prci_tests)
parse_prci_tests(PRCI_NIGHTLY, tests=prci_tests)

parse_azure_tests(AZURE_GATING, tests=azure_tests)
parse_azure_tests(AZURE_NIGHTLY, tests=azure_tests)

missing_in_azure = set(prci_tests) - set(azure_tests + SKIP_IN_AZURE_LIST)
print("missing in Azure tests:", *sorted(missing_in_azure), sep='\n')
if missing_in_azure:
    print(
        "##vso[task.logissue type=warning]"
        "Missing nightly tests in Azure Pipelines, compared to PR-CI",
        missing_in_azure,
    )

extra_in_azure = set(azure_tests) - set(prci_tests + EXTRA_AZURE_LIST)
print("extra Azure tests:", *sorted(extra_in_azure), sep='\n')
if extra_in_azure:
    print(
        "##vso[task.logissue type=warning]"
        "Extra nightly tests in Azure Pipelines, compared to PR-CI",
        extra_in_azure,
    )
