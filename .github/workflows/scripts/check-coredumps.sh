#!/bin/bash -eu

source "${IPA_TESTS_SCRIPTS}/variables-ci.sh"

# check the host first, containers cores were dumped here
COREDUMPS_SUBDIR="coredumps"
COREDUMPS_DIR="${IPA_TESTS_ENV_WORKING_DIR}/${COREDUMPS_SUBDIR}"
rm -rfv "$COREDUMPS_DIR" ||:
mkdir "$COREDUMPS_DIR"
since_time="$(cat coredumpctl.time.mark || echo '-1h')"
sudo coredumpctl --no-pager --since="$since_time" list ||:

pids="$(sudo coredumpctl --no-pager --since="$since_time" -F COREDUMP_PID || echo '')"
# nothing to dump
[ -z "$pids" ] && exit 0

# continue in container
HOST_JOURNAL="/var/log/host_journal"
CONTAINER_COREDUMP="dump_cores"
docker create --privileged \
    -v "$(realpath coredumpctl.time.mark)":/coredumpctl.time.mark:ro \
    -v /var/lib/systemd/coredump:/var/lib/systemd/coredump:ro \
    -v /var/log/journal:"$HOST_JOURNAL":ro \
    -v "${GITHUB_WORKSPACE}":"${IPA_TESTS_REPO_PATH}" \
    --name "$CONTAINER_COREDUMP" "$IPA_DOCKER_IMAGE"
docker start "$CONTAINER_COREDUMP"

docker exec -t \
    "$CONTAINER_COREDUMP" \
    $SHELL_CMD \
        "${IPA_TESTS_REPO_PATH}/${IPA_TESTS_SCRIPTS}/wait-for-systemd.sh"

docker exec -t \
    --env IPA_TESTS_REPO_PATH="${IPA_TESTS_REPO_PATH}" \
    --env IPA_TESTS_SCRIPTS="${IPA_TESTS_REPO_PATH}/${IPA_TESTS_SCRIPTS}" \
    --env IPA_PLATFORM="${IPA_PLATFORM}" \
    "$CONTAINER_COREDUMP" \
    $SHELL_CMD \
        "${IPA_TESTS_REPO_PATH}/${IPA_TESTS_SCRIPTS}/install-debuginfo.sh"

docker exec -t \
    --env IPA_TESTS_REPO_PATH="${IPA_TESTS_REPO_PATH}" \
    --env COREDUMPS_SUBDIR="$COREDUMPS_SUBDIR" \
    --env HOST_JOURNAL="$HOST_JOURNAL" \
    "$CONTAINER_COREDUMP" \
    $SHELL_CMD \
        "${IPA_TESTS_REPO_PATH}/${IPA_TESTS_SCRIPTS}/dump-cores.sh"
# there should be no crashes

printf "Check the CI's artifacts for the full backtrace and coredump\n"
exit 1
