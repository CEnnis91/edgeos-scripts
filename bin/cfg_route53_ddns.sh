#!/bin/bash
# cfg_route53_ddns.sh - adds dynamic dns entry for route53

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$SELF_DIR")"

# shellcheck disable=SC1090
. "${ROOT_DIR}/lib/vyatta.sh"

FREQUENCY="5m"
UPDATE_BIN="${BIN_DIR}/route53_update_record.sh"

while getopts ":i:a:k:s:b:f:" opt; do
    case $opt in
        # [interface] network interface to get the IP from
        i)  INTERFACE="$OPTARG" ;;
        # [access key] AWS access key
        a)  ACCESS_KEY="$OPTARG" ;;
        # [secret key] AWS secret access key
        k)  SECRET_KEY="$OPTARG" ;;
        # [subdomain] subdomain to use with the dynamic dns
        s)  SUBDOMAIN="$OPTARG" ;;

        # [script] script or tool to call to update the dns (optional)
        b)  UPDATE_BIN="$OPTARG" ;;
        # [frequency] how often to run the update task (optional)
        f)  FREQUENCY="$OPTARG" ;;

        *)  echo "ERROR: invalid argument -${OPTARG}"
            generate_getopts_help "$0" "opt"
            exit 1
            ;;
    esac
done

# ensure the arguments are correct
if [[ -z "$SUBDOMAIN" || -z "$ACCESS_KEY" || -z "$SECRET_KEY" || -z "$INTERFACE" ]]; then
    generate_getopts_help "$0" "opt"
    exit 1
fi

if [[ ! -x "$UPDATE_BIN" ]]; then
    echo "ERROR: the update tool '${UPDATE_BIN}' is not valid"
    exit 2
fi

UPDATE_TASK="route53-update-${SUBDOMAIN//./_}"
UPDATE_ARGS="${SUBDOMAIN} ${ACCESS_KEY} ${SECRET_KEY} ${INTERFACE}"

SCRIPT=$(cat <<EOF
    # set renewal task
    set system task-scheduler task $UPDATE_TASK executable path $UPDATE_BIN
    set system task-scheduler task $UPDATE_TASK interval $FREQUENCY
    set system task-scheduler task $UPDATE_TASK executable arguments "$UPDATE_ARGS"
    commit
EOF
)

if check_config "system task-scheduler task $UPDATE_TASK"; then
    SCRIPT="$(echo -e "delete system task-scheduler task ${UPDATE_TASK}\n${SCRIPT}")"
fi

echo "INFO: Running initial task"
if [[ "$DEBUG" == "1" ]]; then
    echo "${UPDATE_BIN} ${UPDATE_ARGS}"
else
    # shellcheck disable=SC2086
    "${UPDATE_BIN}" ${UPDATE_ARGS}
fi

RESULT="$?"
if [[ "$RESULT" != "0" ]]; then
    echo "ERROR: There was an issue running the initial task"
    exit $RESULT
fi

echo "INFO: Adding update task to the config"
exec_config "$SCRIPT"
