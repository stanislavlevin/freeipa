import argparse
import copy
import pprint
import json

import yaml

parser = argparse.ArgumentParser(description='Generate GHA jobs matrix.')
parser.add_argument(
    "gha_template",
    help="path to GHA template",
    nargs="+"
)

parser.add_argument('max_gha_env_jobs', type=int,
                    help='maximum number of Docker envs within VM')

args = parser.parse_args()
SERVICES = {"server", "replica", "client"}

matrix_jobs = []

for template in args.gha_template:
    with open(template, encoding="utf-8") as f:
        data = yaml.safe_load(f)
        default_resources = data["default_resources"]
        for vm in data['vms']:
            vm_jobs = vm['vm_jobs']
            job_name = f'{vm_jobs[0]["container_job"]}_1'
            vm_jobs_number = len(vm_jobs)
            if vm_jobs_number > args.max_gha_env_jobs:
                raise ValueError(
                    f"Number of defined jobs:{vm_jobs_number} within VM:"
                    f"'{job_name}' is greater than limit:"
                    f"{args.max_gha_env_jobs}"
                )

            job_name = f'{job_name}_to_{vm_jobs_number}'

            if job_name in (j["ipa_tests_job_name"] for j in matrix_jobs):
                raise ValueError(f"Job names should be unique:{job_name}")

            jobs = {"ipa_tests_job_name": job_name, "ipa_tests_env": {}}
            tests_env = jobs["ipa_tests_env"]
            tests_env["IPA_TESTS_TOTAL_ENVS"] = vm_jobs_number

            for job_id, vm_job in enumerate(vm_jobs, 1):
                # for hacking runner log
                jobs[f"ipa_tests_env_name_{job_id}"] = vm_job["container_job"]

                tests_env[f'IPA_TESTS_ENV_NAME_{job_id}'] = vm_job[
                    'container_job'
                ]
                tests_env[f'IPA_TESTS_TO_RUN_{job_id}'] = ' '.join(
                    vm_job['tests']
                )
                tests_env[f'IPA_TESTS_TO_IGNORE_{job_id}'] = ' '.join(
                    vm_job.get('ignore', '')
                )
                tests_env[f'IPA_TESTS_TYPE_{job_id}'] = vm_job.get(
                    'type', 'integration'
                )
                tests_env[f'IPA_TESTS_ARGS_{job_id}'] = vm_job.get('args', '')
                tests_env[f'IPA_TESTS_NETWORK_INTERNAL_{job_id}'] = vm_job.get(
                    'isolated', 'false'
                )

                containers = vm_job.get('containers')
                cont_resources = copy.deepcopy(default_resources)
                replicas = 0
                clients = 0
                if containers:
                    replicas = containers.get('replicas', 0)
                    clients = containers.get('clients', 0)

                    resources = containers.get("resources")
                    if resources:
                        for cont in SERVICES:
                            cont_resources[cont].update(
                                resources.get(cont, {})
                            )

                tests_env[f'IPA_TESTS_REPLICAS_{job_id}'] = replicas
                tests_env[f'IPA_TESTS_CLIENTS_{job_id}'] = clients

                for cont in SERVICES:
                    for res in [
                        "mem_limit", "memswap_limit", "mem_reservation"
                    ]:
                        key = f"IPA_TESTS_{cont.upper()}_{res.upper()}_{job_id}"
                        tests_env[key] = cont_resources[cont][res]

            matrix_jobs.extend([jobs])


pprint.pprint(matrix_jobs)
print(
    "::set-output name=matrix::{include}".format(
        include=json.dumps({"include": matrix_jobs})
    )
)
