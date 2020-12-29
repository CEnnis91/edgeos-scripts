#!/bin/bash
# shellcheck disable=SC1090,SC2154
# acme.sh - acme.sh related functions

__SELF_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
# shellcheck disable=SC1090
. "${__SELF_DIR}/globals.sh"

ACME_REVISION="2.8.8"
SUPPORT_AWS="1"

ACME_DIR="${ETC_DIR}/acme"
ACME_SOURCE="$(mktemp)"
DNSAPI_DIR="${ACME_DIR}/dnsapi"

RELOAD_DIR="${BIN_DIR}/reload"

# shellcheck disable=SC2034
RELOAD_BIN="${RELOAD_DIR}/update_webui.sh"
# shellcheck disable=SC2034
RENEW_BIN="${BIN_DIR}/acme_renew.sh"

get_acme_sh() {
    local revision="${1:-master}"
    local script="${ACME_DIR}/acme.sh"

    if [[ ! -d "$ACME_DIR" ]]; then
        mkdir -p "$ACME_DIR"
    fi

    if [[ ! -x "${script}" ]]; then
        # we don't want the entire project so we won't use https://get.acme.sh | sh here
        curl -so "$script" "https://raw.githubusercontent.com/acmesh-official/acme.sh/${revision}/acme.sh"
        chmod +x "$script"
    fi
}

get_acme_dnsapi() {
    local revision="${1:-master}"
    local dnsapi="$2"
    local script="${DNSAPI_DIR}/dns_${dnsapi}.sh"

    get_acme_sh "$revision"

    if [[ ! -d "$DNSAPI_DIR" ]]; then
        mkdir -p "$DNSAPI_DIR"
    fi

    if [[ ! -x "${script}" ]]; then
        curl -so "$script" "https://raw.githubusercontent.com/acmesh-official/acme.sh/${revision}/dnsapi/dns_${dnsapi}.sh"
        chmod +x "$script"
    fi
}

# soft source acme.sh to gain access to functions
# this will be somewhat prone to breaking
get_acme_sh "$ACME_REVISION"
cp -f "${ACME_DIR}/acme.sh" "$ACME_SOURCE"
sed -i 's/^\(main "$@"\)$/# \1/g' "$ACME_SOURCE"

. "$ACME_SOURCE"
if [[ "$SUPPORT_AWS" == "1" ]]; then
    get_acme_dnsapi "$ACME_REVISION" "aws"
    . "${DNSAPI_DIR}/dns_aws.sh"
fi

aws_change_record() {
    local domain_id="$1"
    local payload="$2"

    local action=""
    local type=""
    action="$(echo "$payload" | grep -o "<Action>[^<]*" | cut -d'>' -f2)"
    type="$(echo "$payload" | grep -o "<Type>[^<]*" | cut -d'>' -f2)"

    if aws_rest POST "2013-04-01${domain_id}/rrset/" "" "$payload" && _contains "$response" "ChangeResourceRecordSetsResponse"; then
        _info "${type} record ${action}ed successfully."

        if [ -n "$AWS_DNS_SLOWRATE" ]; then
            _info "Slow rate activated: sleeping for ${AWS_DNS_SLOWRATE} seconds"
            _sleep "$AWS_DNS_SLOWRATE"
        else
            _sleep 1
        fi

        # global values set by aws_rest
        _debug resource "$resource"
        return 0
    fi

    return 1
}

aws_check_credentials() {
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        _use_container_role || _use_instance_role
    fi

    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        AWS_ACCESS_KEY_ID=""
        AWS_SECRET_ACCESS_KEY=""
        return 1
    fi
}

aws_format_records() {
    local payload="$1"
    local fqdn="$2"

    local formatted=""
    local rr="ResourceRecords"

    formatted="$(echo "$payload" | sed 's/<ResourceRecordSet>/"/g' | tr '"' "\n" | grep "<Name>${fqdn}.</Name>" | _egrep_o "<${rr}.*</${rr}>" | sed "s/<${rr}>//" | sed "s#</${rr}>##")"
    echo "$formatted"
}

aws_get_records() {
    local domain_id="$1"
    local fqdn="$2"
    local record_type="$3"

    _info "Getting existing records for ${fqdn}"
    if ! aws_rest GET "2013-04-01${domain_id}/rrset" "name=${fqdn}&type=${record_type}"; then
        return 1
    fi

    # global values set by aws_rest
    _debug resource "$resource"
}

aws_get_zone() {
    local fqdn="$1"

    # _get_root expects its parameter to be a subdomain
    if ! _get_root "junkjunkjunk.${fqdn}"; then
        _err "Invalid domain '${fqdn}'"
        return 1
    fi

    # global values set by _get_root
    _debug _domain_id "$_domain_id"
    _debug _sub_domain "$_sub_domain"
    _debug _domain "$_domain"
}

aws_update_record() {
    action="$1"
    fulldomain="$2"
    recordtype="$3"
    recordvalue="$4"
    ttl="${5:-300}"

    # do not group existing records during an upsert
    # warning: advanced, use with care
    if _contains "$action" "SINGLE"; then
        action="$(echo "$action" | cut -d'-' -f1)"
        singlerecord="1"
    else
        singlerecord="0"
    fi

    # don't let data carry over from previous requests
    response=""; _resource_record=""

    if ! aws_get_zone "$fulldomain"; then _sleep 1; return 1; fi
    if ! aws_get_records "$_domain_id" "$fulldomain" "$recordtype"; then _sleep 1; return 1; fi

    # handle existing records
    if _contains "$response" "<Name>$fulldomain.</Name>"; then
        case "$action" in
            CREATE) ;;
            DELETE|UPSERT)
                _resource_record="$(aws_format_records "$response" "$fulldomain")"
                _debug "_resource_record" "$_resource_record"
                ;;
            *)  _err "Invalid action '$action'"; _sleep 1; return 1 ;;
        esac

        # do not group existing records during an action
        if [[ "$singlerecord" == "1" ]]; then
            _resource_record=""
        fi
    else
        case "$action" in
            CREATE|UPSERT)  ;;
            DELETE)         _debug "No records exist, skipping"; _sleep 1; return 0 ;;
            *)              _err "Invalid action '$action'"; _sleep 1; return 1 ;;
        esac
    fi

    # check if the record already has this value
    if [[ "$_resource_record" || "$action" == "CREATE" ]] && _contains "$response" "$recordvalue"; then
        case "$action" in
            CREATE|UPSERT)  _info "The ${recordtype} record already exists, skipping."; _sleep 1; return 0 ;;
            DELETE)         ;;
        esac
    fi

    # handle resource value differently based on record type
    case $recordtype in
        TXT)    quote="\"" ;;
        *)      quote='' ;;
    esac

    # build the change resource request
    case $action in
        CREATE|UPSERT)  _aws_tmpl_xml="<ChangeResourceRecordSetsRequest xmlns=\"https://route53.amazonaws.com/doc/2013-04-01/\"><ChangeBatch><Changes><Change><Action>${action}</Action><ResourceRecordSet><Name>${fulldomain}</Name><Type>${recordtype}</Type><TTL>${ttl}</TTL><ResourceRecords>${_resource_record}<ResourceRecord><Value>${quote}${recordvalue}${quote}</Value></ResourceRecord></ResourceRecords></ResourceRecordSet></Change></Changes></ChangeBatch></ChangeResourceRecordSetsRequest>" ;;
        DELETE)         _aws_tmpl_xml="<ChangeResourceRecordSetsRequest xmlns=\"https://route53.amazonaws.com/doc/2013-04-01/\"><ChangeBatch><Changes><Change><Action>${action}</Action><ResourceRecordSet><ResourceRecords>${_resource_record}</ResourceRecords><Name>${fulldomain}.</Name><Type>${recordtype}</Type><TTL>${ttl}</TTL></ResourceRecordSet></Change></Changes></ChangeBatch></ChangeResourceRecordSetsRequest>" ;;
    esac

    if ! aws_change_record "$_domain_id" "$_aws_tmpl_xml"; then _sleep 1; return; fi
}
