#!/bin/bash -eu

source "${IPA_TESTS_SCRIPTS}/variables-ci.sh"

workdir="$IPA_TESTS_ENV_WORKING_DIR"
rm -rf "$workdir"
mkdir "$workdir"

ln -sfr \
    ${GITHUB_WORKSPACE}/${IPA_TESTS_SCRIPTS}/{run-tests.sh,setup_containers.py} \
    ./

function runner() {
    set -o pipefail
    local project_id="$1"
    local project_name_varname="IPA_TESTS_ENV_NAME_${project_id}"
    local project_name="${!project_name_varname}"
    [ -z "$project_name" ] &&
        { echo "Project name is not set for project:${project_id}"; exit 1 ;}
    local workdir="$IPA_TESTS_ENV_WORKING_DIR"
    local logfile="runner_${project_name}.log"
    local project_dir="${workdir}/${project_name}"
    rm -rf "$project_dir"
    mkdir "$project_dir"
    # live-logging of tests within environment: '1'
    if [ "$project_id" == "1" ]; then
        /usr/bin/time \
            --format="tests: ${project_name}, result: %x, time: %E" \
            --output="result_${project_id}" \
            -- \
            ./run-tests.sh "$project_id" 2>&1 |
            ts '[%Y-%m-%d %H:%M:%S]' 2>&1 | tee "${project_dir}/${logfile}"
        result=$?
    else
        /usr/bin/time \
            --format="tests: ${project_name}, result: %x, time: %E" \
            --output="result_${project_id}" \
            -- \
            ./run-tests.sh "$project_id" 2>&1 |
            ts '[%Y-%m-%d %H:%M:%S]' 2>&1 > "${project_dir}/${logfile}"
        result=$?
    fi
    exit $result
}
export -f runner

# clear page cache to make application think the system has more memory
# /sys/fs/cgroup/memory/memory.usage_in_bytes = rss + page cache
while : ; do
    sleep 1m
    sudo $SHELL_CMD_NODEBUG -c 'sync; echo 1 > /proc/sys/vm/drop_caches'
done &

result=1
rm -f result_*
{ parallel \
    --tag \
    --jobs $MAX_CONTAINER_ENVS \
    --linebuffer \
    'runner {}' ::: "$(seq $IPA_TESTS_TOTAL_ENVS)" && result=0 ; } ||
        result=$?
echo "Results:"
cat $(eval echo result_{1..$IPA_TESTS_TOTAL_ENVS})
exit $result
