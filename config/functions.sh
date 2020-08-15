#!/bin/bash
# functions

CLI_API="$(command -v cli-shell-api)"
if [[ -z "$CLI_API" ]]; then
	echo "ERROR: cannot find cli-shell-api"
	exit 1
fi

# determines if a node already exists in the active config
# example: config_exists "system" "package"
config_exists() {
	# shellcheck disable=SC2155
	local key="$*"

	# shellcheck disable=SC2086
	# shellcheck disable=SC2155
	local output="$($CLI_API showConfig $key --show-active-only)"
    case $output in
        *is\ empty)		return 1 ;;
        *not\ valid)	echo "$output"; return 0 ;;
        *)				return 0 ;;
    esac
}

show_config() {
	# shellcheck disable=SC2155
	local key="$*"
	
	# shellcheck disable=SC2086
	$CLI_API showConfig $key --show-active-only
}