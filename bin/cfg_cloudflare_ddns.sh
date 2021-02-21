#!/bin/bash
# cfg_cloudflare_ddns.sh - adds dynamic dns entry for cloudflare
# other services can be added from the web interface, this still uses ddclient
# https://help.ui.com/hc/en-us/articles/204976324-EdgeRouter-Custom-Dynamic-DNS

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$SELF_DIR")"

# shellcheck disable=SC1090
. "${ROOT_DIR}/lib/vyatta.sh"

API_ENDPOINT="api.cloudflare.com/client/v4"

while getopts ":i:l:p:s:e:" opt; do
    case $opt in
        # [interface] network interface to get the IP from
        i)  INTERFACE="$OPTARG" ;;
        # [login] cloudflare login information (usually email)
        l)  LOGIN="$OPTARG" ;;
        # [password] cloudflare password or API token
        p)  PASSWORD="$OPTARG" ;;
        # [subdomain] subdomain to use with the dynamic dns
        s)  SUBDOMAIN="$OPTARG" ;;

        # [api endpoint] cloudflare endpoint to post to (optional)
        e)  API_ENDPOINT="$OPTARG" ;;

        *)  echo "ERROR: invalid argument -${OPTARG}"
            generate_getopts_help "$0" "opt"
            exit 1
            ;;
    esac
done

# ensure the arguments are correct
if [[ -z "$SUBDOMAIN" || -z "$LOGIN" || -z "$PASSWORD" || -z "$INTERFACE" ]]; then
    generate_getopts_help "$0" "opt"
    exit 1
fi

DOMAIN="$(echo "$SUBDOMAIN" | awk -F. '{print $(NF-1) FS $NF}')"
SERVICE_NAME="custom-${SUBDOMAIN//./_}"
SCRIPT=$(cat <<EOF
    set service dns dynamic interface $INTERFACE service $SERVICE_NAME host-name $SUBDOMAIN
    set service dns dynamic interface $INTERFACE service $SERVICE_NAME login $LOGIN
    set service dns dynamic interface $INTERFACE service $SERVICE_NAME password $PASSWORD
    set service dns dynamic interface $INTERFACE service $SERVICE_NAME protocol cloudflare
    set service dns dynamic interface $INTERFACE service $SERVICE_NAME options zone=${DOMAIN}
    set service dns dynamic interface $INTERFACE service $SERVICE_NAME server $API_ENDPOINT
    commit
EOF
)

if check_config "service dns dynamic interface $INTERFACE service $SERVICE_NAME"; then
    SCRIPT="$(echo -e "delete service dns dynamic interface $INTERFACE service ${SERVICE_NAME}\n${SCRIPT}")"
fi

echo "INFO: Adding dynamic DNS service for $SUBDOMAIN to the config"
echo "INFO: To show the status use: 'show dns dynamic status'"
echo "INFO: To force update the values use: 'update dns dynamic interface $INTERFACE'"
exec_config "$SCRIPT"
