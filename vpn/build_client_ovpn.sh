#!/bin/bash
# shellcheck disable=SC2034
# build_client_ovpn.sh - create a client ovpn config for a user
# https://help.ui.com/hc/en-us/articles/115015971688-EdgeRouter-OpenVPN-Server

HOST="$1"
CLIENT_PEM="$2"
CLIENT_KEY="$3"
TEMPLATE="${4:-template.ovpn}"

# ensure the arguments are correct
# other variables can be changed at the command line
if [[ -z "$HOST" || -z "$CLIENT_PEM" || -z "$CLIENT_KEY" ]]; then
    echo "ERROR: invalid arguments"
    echo "$(basename "$0") <template> <host> <client certificate (*.pem)> <client key (*.key) [template]>"
    exit 1
fi

# ensure that cert files exist
CONFIG_AUTH="/config/auth"
FILES=( "${CONFIG_AUTH}/cacert.pem" "${CONFIG_AUTH}/ta.key" "$CLIENT_PEM" "$CLIENT_KEY" )
for file in "${FILES[@]}"; do
    if [[ ! -e "${file}" ]]; then
        echo "ERROR: file '$(basename "${file}")' is missing"
        exit 1
    fi
done

CA="$(echo -e "<ca>\n$(openssl x509 -in "${CONFIG_AUTH}/cacert.pem")\n</ca>")"
CERT="$(echo -e "<cert>\n$(openssl x509 -in "${CLIENT_PEM}" -text)\n</cert>")"
COMMON_NAME="$(openssl x509 -in "${CLIENT_PEM}" -noout -subject | sed 's/,/\n/g' | grep "CN =" | awk '{print $NF}')"
KEY="$(echo -e "<key>\n$(cat "${CLIENT_KEY}")\n</key>")"
TA="$(echo -e "<tls-auth>\n$(cat "${CONFIG_AUTH}/ta.key")\n</tls-auth>")"

# shellcheck disable=SC2002
REQUIRED="$(cat "$TEMPLATE" | grep -o "\${[^:}]\+}" | sed 's/${\|}//g')"
for require in $REQUIRED; do
    if [[ -z "${!require}" ]]; then
        echo "ERROR: required variable '${require}' not defined"
        exit 1
    fi
done

eval "echo \"$(cat "$TEMPLATE")\""
