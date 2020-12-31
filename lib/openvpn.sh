#!/bin/bash
# openvpn.sh

__SELF_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
# shellcheck disable=SC1090
. "${__SELF_DIR}/globals.sh"

DEFAULT_INTERFACE="vtun0"
DEFAULT_TEMPLATE="simple"
OPENVPN_DIR="${ETC_DIR}/openvpn"
TEMPLATE_DIR="${SHARE_DIR}/ovpn"

get_server_path() {
    local interface="${1:-${DEFAULT_INTERFACE}}"
    local path="${OPENVPN_DIR}/${interface}"

    if [[ -d "$path" ]]; then
        echo "$path"
    fi
}

get_key_path() {
    local key="$1"
    local interface="${2:-${DEFAULT_INTERFACE}}"

    local server=""
    server="$(get_server_path "$interface")"

    if [[ ! -e "$key" ]]; then
        if [[ -e "${server}/${key}" ]]; then
            echo "${server}/${key}"
        fi
    else
        echo "$key"
    fi
}

get_template_path() {
    local template="${1:-${DEFAULT_TEMPLATE}}"
    local path="${TEMPLATE_DIR}/${template}.ovpn"

    if [[ -e "$path" ]]; then
        echo "$path"
    fi
}
