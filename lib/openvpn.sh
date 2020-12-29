#!/bin/bash
# openvpn.sh - openvpn specific functions

__SELF_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck disable=SC1090
. "${__SELF_DIR}/globals.sh"

DEFAULT_INTERFACE="vtun0"
DEFAULT_TEMPLATE="basic"
OPENVPN_DIR="${ETC_DIR}/openvpn"
TEMPLATE_DIR="${SHARE_DIR}/ovpn"

get_server_path() {
    local interface="${1:-${DEFAULT_INTERFACE}}"
    local path="${OPENVPN_DIR}/${interface}"

    if [[ -d "$path" ]]; then
        echo "$path"
    else
        echo ""
    fi
}

get_template_path() {
    local template="${1:-${DEFAULT_TEMPLATE}}"
    local path="${TEMPLATE_DIR}/${template}.ovpn"

    if [[ -e "$path" ]]; then
        echo "$path"
    else
        echo ""
    fi
}
