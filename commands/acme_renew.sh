#!/bin/bash
# acme_renew.sh - renew a let's encrypt certificate with acme.sh
# based on https://github.com/hungnguyenm/edgemax-acme

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$SELF_DIR")"
ACME_DIR="${ROOT_DIR}/secure/acme"

UTIL_DIR="${ROOT_DIR}/utilities"
ACME_RELOAD="${UTIL_DIR}/acme_reload.sh"

# shellcheck disable=SC1090
. "${SELF_DIR}/functions/acme.sh"

usage() {
    echo "Usage: $0 -d <mydomain.com> [-d <additionaldomain.com>] -n <dns service>" \
         "[-i set insecure flag] [-v enable acme verbose] [-r reload flag]" \
         "-t <tag> [-t <additional tag>] -k <key> [-k <additional key>]" 1>&2; exit 1;
}

kill_and_wait() {
    local pid=$1
    [ -z "$pid" ] && return

    kill -s INT "$pid" 2> /dev/null
    # shellcheck disable=SC2009
    ps -e | grep lighttpd | awk '{print $1;}' | sudo xargs kill
    while kill -s SIGTERM "$pid" 2> /dev/null; do
        sleep 1
    done
}

log() {
    if [ -z "$2" ]
    then
        printf -- "%s %s\n" "[$(date)]" "$1"
    fi
}

INSECURE_FLAG=""
RELOAD_FLAG=1
VERBOSE_FLAG=""

# first parse our options
while getopts ":hivd:n:t:k:r:" opt; do
    case $opt in
        d) DOMAINS+=("$OPTARG");;
        i) INSECURE_FLAG="--insecure";;
        n) DNS=$OPTARG;;
        t) TAGS+=("$OPTARG");;
        k) KEYS+=("$OPTARG");;
        v) VERBOSE_FLAG="--debug 2";;
        r) RELOAD_FLAG=$OPTARG;;
        h | *)
          usage
          ;;
    esac
done
shift $((OPTIND -1))

if [ "$RELOAD_FLAG" -ne 0 ] && [ "$RELOAD_FLAG" -ne 1 ]; then
    RELOAD_FLAG=1
fi

# check for required parameters
if [ ${#DOMAINS[@]} -eq 0 ] || [ -z ${DNS+x} ] \
        || [ ${#TAGS[@]} -eq 0 ] || [ ${#KEYS[@]} -eq 0 ] || [ ${#TAGS[@]} -ne ${#KEYS[@]} ]; then
    usage
fi

# prepare flags for acme.sh
for val in "${DOMAINS[@]}"; do
     DOMAINARG+="-d $val "
done
DNSARG="--dns $DNS"

log "Getting dnsapi."
get_acme_dnsapi "${DNS##*_}"

# prepare environment
for i in "${!TAGS[@]}"; do
    # shellcheck disable=SC2086
    export ${TAGS[$i]}="${KEYS[$i]}"
done

log "Stopping gui service."
if [ -e "/var/run/lighttpd.pid" ]; then
    if command -v killall >/dev/null 2>&1; then
        killall lighttpd
        # shellcheck disable=SC2009
        ps -e | grep lighttpd | awk '{print $1;}' | sudo xargs kill
    else
        kill_and_wait "$(pidof lighttpd)"
    fi
fi

ACME_TEMP="$(mktemp -d)"
if [ $RELOAD_FLAG -eq 1 ]; then
    RELOAD_CMD="--reloadcmd \"${ACME_RELOAD} \"${ACME_TEMP}\""
else
    RELOAD_CMD=""
fi

log "Executing acme.sh."
# shellcheck disable=SC2068
"${ACME_DIR}/acme.sh" --issue "$DNSARG" "$DOMAINARG" --home "$ACME_DIR" \
    --keylength ec-384 --keypath "${ACME_TEMP}/server.key" --fullchainpath "${ACME_TEMP}/full.cer" \
    --log /var/log/acme.log "$RELOAD_CMD" \
    "$INSECURE_FLAG" "$VERBOSE_FLAG" $@

log "Starting gui service."
/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
