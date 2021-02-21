#!/bin/bash
# shellcheck disable=SC2034
# ovpn_gen_client.sh - create a client ovpn config for a user
# https://help.ui.com/hc/en-us/articles/115015971688-EdgeRouter-OpenVPN-Server

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$SELF_DIR")"

# shellcheck disable=SC1090
. "${ROOT_DIR}/lib/openvpn.sh"

HOST="$1"
CLIENT_PEM="$2"
CLIENT_KEY="$3"
TEMPLATE_NAME="${4:-${DEFAULT_TEMPLATE}}"
CERT_DIR="${5:-$(get_server_path)}"

CLIENT_PEM_PATH="$(get_key_path "$CLIENT_PEM")"
CLIENT_KEY_PATH="$(get_key_path "$CLIENT_KEY")"
TEMPLATE_PATH="$(get_template_path "$TEMPLATE_NAME")"

# ensure the arguments are correct
# other variables can be changed at the command line
if [[ -z "$HOST" || -z "$CLIENT_PEM_PATH" || -z "$CLIENT_KEY_PATH" || -z "$TEMPLATE_PATH" || -z "$CERT_DIR" ]]; then
    echo "ERROR: invalid arguments"
    echo "$(basename "$0") <host> <client certificate (*.pem)> <client key (*.key)> [template] [cert dir]"
    exit 1
fi

# ensure that cert files exist
FILES=( "${CERT_DIR}/cacert.pem" "${CERT_DIR}/ta.key" "$CLIENT_PEM_PATH" "$CLIENT_KEY_PATH" )
for file in "${FILES[@]}"; do
    if [[ ! -e "${file}" ]]; then
        echo "ERROR: file '${file}' is missing"
        exit 1
    fi
done

CA="$(echo -e "<ca>\n$(openssl x509 -in "${CERT_DIR}/cacert.pem")\n</ca>")"
CERT="$(echo -e "<cert>\n$(openssl x509 -in "${CLIENT_PEM_PATH}" -text)\n</cert>")"
COMMON_NAME="$(openssl x509 -in "${CLIENT_PEM_PATH}" -noout -subject | sed 's/,/\n/g' | grep "CN =" | awk '{print $NF}')"
KEY="$(echo -e "<key>\n$(cat "${CLIENT_KEY_PATH}")\n</key>")"
TA="$(echo -e "<tls-auth>\n$(cat "${CERT_DIR}/ta.key")\n</tls-auth>")"

# shellcheck disable=SC2002
REQUIRED="$(cat "$TEMPLATE_PATH" | grep -o "\${[^:}]\+}" | sed 's/${\|}//g')"
for require in $REQUIRED; do
    if [[ -z "${!require}" ]]; then
        echo "ERROR: required variable '${require}' not defined"
        exit 1
    fi
done

# dump the config to shell
eval "echo \"$(cat "$TEMPLATE_PATH")\""
