#!/bin/bash
# add_cloudflare_dyndns.sh - adds dynamic dns entry for cloudflare
# https://help.ui.com/hc/en-us/articles/204976324-EdgeRouter-Custom-Dynamic-DNS

vyatta_ddns() {
    local action="$1"
    local interface="$2"

    local vyatta_ddns="/opt/vyatta/bin/sudo-users/vyatta-op-dynamic-dns.pl"
    if [[ ! -e "$vyatta_ddns" ]]; then
        echo "ERROR: cannot find vyatta-op-dynamic-dns.pl"
        exit 1
    fi

    case "$action" in
        show)   
    esac
}

if [[ 'vyattacfg' != "$(id -ng)" ]]; then
    exec sg vyattacfg -c "$0 $*"
fi

. functions.sh

SUBDOMAIN="$1"
LOGIN="$2"
PASSWORD="$3"
INTERFACE="$4"

# ensure the arguments are correct
if [[ -z "$SUBDOMAIN" || -z "$LOGIN" || -z "$PASSWORD" || -z "$INTERFACE" ]]; then
    echo "ERROR: invalid arguments"
    echo "$(basename "$0") <subdomain> <login> <api-key> <interface>"
    exit 1
fi

API_SERVER="api.cloudflare.com/client/v4"
DOMAIN="$(echo "$SUBDOMAIN" | awk -F. '{print $(NF-1) FS $NF}')"
SERVICE_NAME="custom-${SUBDOMAIN//.}"

if check_config "service dns dynamic interface $INTERFACE service $SERVICE_NAME"; then
    echo "INFO: Dynamic DNS service already exists in the config"
    exec_config "show service dns dynamic interface $INTERFACE"
    exit 0
fi

SCRIPT=$(cat <<EOF
    set service dns dynamic interface $INTERFACE service $SERVICE_NAME host-name $SUBDOMAIN
    set service dns dynamic interface $INTERFACE service $SERVICE_NAME login $LOGIN
    set service dns dynamic interface $INTERFACE service $SERVICE_NAME password $PASSWORD
    set service dns dynamic interface $INTERFACE service $SERVICE_NAME protocol cloudflare
    set service dns dynamic interface $INTERFACE service $SERVICE_NAME options zone=${DOMAIN}
    set service dns dynamic interface $INTERFACE service $SERVICE_NAME server $API_SERVER
    commit
EOF
)

echo "INFO: Adding dynamic DNS service for $SUBDOMAIN to config"
echo "INFO: To show the status use: 'show dns dynamic status'"
echo "INFO: To force update the values use: 'update dns dynamic interface $INTERFACE'"
exec_config "$SCRIPT"