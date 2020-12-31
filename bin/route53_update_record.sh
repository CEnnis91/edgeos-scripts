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

SUBDOMAIN="$1"
AWS_ACCESS_KEY_ID="$2"
AWS_SECRET_ACCESS_KEY="$3"
INTERFACE="$4"

# ensure the arguments are correct
if [[ -z "$SUBDOMAIN" || -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" || -z "$INTERFACE" ]]; then
    echo "ERROR: invalid arguments"
    echo "$(basename "$0") <subdomain> <access-key> <secret-key> <interface>"
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
aws_update_record "$ACTION" "$SUBDOMAIN" "A" "$INTERFACE_IP"
