#!/bin/bash
# cfg_route53_ddns.sh - adds dynamic dns entry for route53

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$SELF_DIR")"

# shellcheck disable=SC1090
. "${ROOT_DIR}/lib/vyatta.sh"

SUBDOMAIN="$1"
ACCESS_KEY="$2"
SECRET_KEY="$3"
INTERFACE="$4"

# ensure the arguments are correct
if [[ -z "$SUBDOMAIN" || -z "$ACCESS_KEY" || -z "$SECRET_KEY" || -z "$INTERFACE" ]]; then
    echo "ERROR: invalid arguments"
    echo "$(basename "$0") <subdomain> <access-key> <secret-key> <interface>"
    exit 1
fi

UPDATE_BIN="${BIN_DIR}/route53_update_record.sh"
UPDATE_TASK="rt53.update.${SUBDOMAIN}"
UPDATE_ARGS="${SUBDOMAIN} ${ACCESS_KEY} ${SECRET_KEY} ${INTERFACE}"

if check_config "system task-scheduler task $UPDATE_TASK"; then
    echo "INFO: system task-scheduler task '${UPDATE_TASK}' already exists in the config"
    exec_config "show system task-scheduler task $UPDATE_TASK"
    exit 0
fi

SCRIPT=$(cat <<EOF
    # set renewal task
    set system task-scheduler task $UPDATE_TASK executable path $UPDATE_BIN
    set system task-scheduler task $UPDATE_TASK interval 5m
    set system task-scheduler task $UPDATE_TASK executable arguments "$UPDATE_ARGS"
    commit
EOF
)

echo "INFO: Adding update task to the config"
exec_config "$SCRIPT"
