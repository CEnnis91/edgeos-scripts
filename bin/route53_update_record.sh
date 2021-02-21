#!/bin/bash
# update_route53_record.sh - adds dynamic dns entry for route53

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$SELF_DIR")"

# shellcheck disable=SC1090
. "${ROOT_DIR}/lib/acme.sh"

get_interface_ip() {
    local interface="${1:-eth0}"
    ifconfig "$interface" | grep 'inet ' | awk '{print $2}'
}

is_naked_domain() {
    local hostname="$1"

    if [[ "$(echo "$hostname" | grep -o '[.]' | wc -l)" == "1" ]]; then
        return 0
    fi
    return 1
}

while getopts ":i:a:k:s:" opt; do
    case $opt in
        # [interface] network interface to get the IP from
        i)  INTERFACE="$OPTARG" ;;
        # [access key] AWS access key
        a)  AWS_ACCESS_KEY_ID="$OPTARG" ;;
        # [secret key] AWS secret access key
        k)  AWS_SECRET_ACCESS_KEY="$OPTARG" ;;
        # [subdomain] subdomain to use with the dynamic dns
        s)  SUBDOMAIN="$OPTARG" ;;

        *)  echo "ERROR: invalid argument -${OPTARG}"
            generate_getopts_help "$0" "opt"
            exit 1
            ;;
    esac
done

# ensure the arguments are correct
if [[ -z "$SUBDOMAIN" || -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" || -z "$INTERFACE" ]]; then
    generate_getopts_help "$0" "opt"
    exit 1
fi

if ! aws_check_credentials; then
    _err "You haven't specifed the aws route53 api key id and and api key secret yet."
    _err "Please create your key and try again. see $(__green $AWS_WIKI)"
    exit 2
fi

if is_naked_domain "$SUBDOMAIN"; then
    ACTION="UPSERT-SINGLE"
else
    ACTION="UPSERT"
fi

INTERFACE_IP="$(get_interface_ip "$INTERFACE")"

if [[ "$DEBUG" == "1" ]]; then
    echo "aws_update_record '$ACTION' '$SUBDOMAIN' 'A' '$INTERFACE_IP'"
else
    aws_update_record "$ACTION" "$SUBDOMAIN" "A" "$INTERFACE_IP"
fi
