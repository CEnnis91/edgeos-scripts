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
UPDATE_TASK="route53-update-${SUBDOMAIN//./_}"
UPDATE_ARGS="${SUBDOMAIN} ${ACCESS_KEY} ${SECRET_KEY} ${INTERFACE}"

SCRIPT=$(cat <<EOF
    # set renewal task
    set system task-scheduler task $UPDATE_TASK executable path $UPDATE_BIN
    set system task-scheduler task $UPDATE_TASK interval 5m
    set system task-scheduler task $UPDATE_TASK executable arguments "$UPDATE_ARGS"
    commit
EOF
)

if check_config "system task-scheduler task $UPDATE_TASK"; then
    SCRIPT="$(echo -e "delete system task-scheduler task ${UPDATE_TASK}\n${SCRIPT}")"
fi

echo "INFO: Running initial task"
# shellcheck disable=SC2086
"${UPDATE_BIN}" $UPDATE_ARGS

RESULT="$?"
if [[ "$RESULT" != "0" ]]; then
    echo "ERROR: There was an issue running the initial task"
    exit $RESULT
fi

echo "INFO: Adding update task to the config"
exec_config "$SCRIPT"
