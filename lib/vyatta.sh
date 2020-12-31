#!/bin/bash
# vyatta.sh

__SELF_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
# shellcheck disable=SC1090
. "${__SELF_DIR}/globals.sh"

if [[ "$DEBUG" == "1" ]]; then
    CMD_WRAPPER="echo"
else
    CMD_WRAPPER="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper"

    if [[ ! -e "$CMD_WRAPPER" ]]; then
        echo "ERROR: cannot find vyatta-cfg-cmd-wrapper"
        exit 1
    else
        if [[ 'vyattacfg' != "$(id -ng)" ]]; then
            exec sg vyattacfg -c "$0 $*"
        fi
    fi
fi

check_config() {
    # shellcheck disable=SC2155
    local key="$*"

    # shellcheck disable=SC2086,SC2155
    local exists="$(exec_config show $key)"

    case $exists in
        *is\ empty)     return 1 ;;
        *not\ valid)    echo "$exists"; return 0 ;;
        *)              return $DEBUG ;;
    esac
}

exec_config() {
    # shellcheck disable=SC2155
    local commands="$*"

    "$CMD_WRAPPER" begin
    while read -r command; do
        if [[ -n "$command" && ! $command =~ ^[\ \t]*#.*$ ]]; then
            # shellcheck disable=SC2086
            eval "$CMD_WRAPPER" $command
        fi
    done < <(echo "$commands")
    "$CMD_WRAPPER" end
}
