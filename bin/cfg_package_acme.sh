#!/bin/bash
# cfg_package_acme.sh - tar let's encrypt certificates

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$SELF_DIR")"

# shellcheck disable=SC1090
. "${ROOT_DIR}/lib/vyatta.sh"

PACKAGE_BIN="${BIN_DIR}/reload/package_acme_certs.sh"
PACKAGE_TASK="package.acme.certs"

if check_config "system task-scheduler task $PACKAGE_TASK"; then
    echo "INFO: system task-scheduler task '${PACKAGE_TASK}' already exists in the config"
    exec_config "show system task-scheduler task $PACKAGE_TASK"
    exit 0
fi

SCRIPT=$(cat <<EOF
    # set renewal task
    set system task-scheduler task $PACKAGE_TASK executable path $PACKAGE_BIN
    set system task-scheduler task $PACKAGE_TASK interval 1d
    commit
EOF
)

echo "INFO: Adding update task to the config"
exec_config "$SCRIPT"
