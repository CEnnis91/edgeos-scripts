#!/bin/bash
# vyatta.sh - vyatta specific functions

# shellcheck disable=SC1090
. "$(dirname "$0")/globals.sh"

CMD_WRAPPER="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper"
if [[ ! -e "$CMD_WRAPPER" ]]; then
    echo "ERROR: cannot find vyatta-cfg-cmd-wrapper"
    exit 1
fi

check_config() {
    # shellcheck disable=SC2155
    local key="$*"

    # shellcheck disable=SC2086
    # shellcheck disable=SC2155
    local exists="$(exec_config show $key)"

    case $exists in
        *is\ empty)     return 1 ;;
        *not\ valid)    echo "$exists"; return 0 ;;
        *)              return 0 ;;
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
