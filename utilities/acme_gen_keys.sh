#!/bin/bash
# shellcheck disable=SC2001
# acme_gen_keys.sh
# quick tool to generate keys for cfg_letsencrypt_cert.sh from acme.sh documentation

# provider) DNS="dns_provider"; KEYS=( PROVIDER_USERNAME PROVIDER_PASSWORD ) ;;
format_provider() {
    declare -n __p="$1"

    for key in "${!__p[@]}"; do
        short="$(echo "$key" | sed 's/dns_\([^.]\+\).sh/\1/g')"
        printf "\t%s)\tDNS=\"dns_%s\"; KEYS=(%s ) ;;\n" "$short" "$short" "${__p[${key}]}"
    done
}

DNSAPI_DOC="$1"
DNSAPI_DIR="$2"

if [[ ! -f "$DNSAPI_DOC" || ! -d "$DNSAPI_DIR" || "$#" -lt 2 ]]; then
    echo "ERROR: invalid arguments"
    echo "$(basename "$0") <dnsapi.md> <dnsapi dir>"
    exit 1
fi

declare -A PROVIDERS
EXPORTS="$(grep -o "^export.*=" "$DNSAPI_DOC" | sort | uniq)"

while read -r variable; do
    key="$(echo "$variable" | sed 's/export[ ]*\([^=]\+\)=/\1/g')"

    if [[ -n "$key" ]]; then
        dnsapi="$(grep -Rl "$key" "${DNSAPI_DIR}")"
        provider="${dnsapi##*/}"

        if [[ -n "$provider" ]]; then
            PROVIDERS[${provider}]="${PROVIDERS[${provider}]} ${key}"
        fi
    fi
done <<< "$EXPORTS"

# use expand or columns to get nicer output (system specific)
echo -e "\t# GENERATED with $(basename "$0")"
format_provider PROVIDERS | sort
echo -e "\t# END GENERATED section"
