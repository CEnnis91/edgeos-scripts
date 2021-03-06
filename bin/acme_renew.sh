#!/bin/bash
# acme_renew.sh - renew a let's encrypt certificate with acme.sh
# based on https://github.com/hungnguyenm/edgemax-acme

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$SELF_DIR")"

# shellcheck disable=SC1090
. "${ROOT_DIR}/lib/acme.sh"

usage() {
    echo "Usage: $0 -d <mydomain.com> [-d <additionaldomain.com>] -n <dns service>" \
         "[-i set insecure flag] [-v enable acme verbose] [-r reload flag] [-f force flag]" \
         "-t <tag> [-t <additional tag>] -k <key> [-k <additional key>]" 1>&2; exit 1;
}

kill_and_wait() {
    local pid=$1
    [ -z "$pid" ] && return

    kill -s INT "$pid" 2> /dev/null
    # shellcheck disable=SC2009
    ps -e | grep lighttpd | awk '{print $1;}' | sudo xargs kill 2>/dev/null
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

FORCE_FLAG=""
INSECURE_FLAG=""
RELOAD_FLAG=1
VERBOSE_FLAG=""

# first parse our options
while getopts ":fhivd:n:t:k:r:" opt; do
    case $opt in
        d) DOMAINS+=("$OPTARG");;
        f) FORCE_FLAG="--force";;
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
if [[ -e "/var/run/lighttpd.pid" || -n "$(pidof lighttpd)" ]]; then
    if command -v killall >/dev/null 2>&1; then
        killall lighttpd
        # shellcheck disable=SC2009
        ps -e | grep lighttpd | awk '{print $1;}' | sudo xargs kill 2> /dev/null
    else
        kill_and_wait "$(pidof lighttpd)"
    fi
fi

ACME_TEMP="$(mktemp -d)"
if [ $RELOAD_FLAG -eq 1 ]; then
    RELOAD_CMD="${RELOAD_BIN} ${ACME_TEMP}"
else
    RELOAD_CMD="true"
fi

log "Executing acme.sh."
# shellcheck disable=SC2068,SC2086
"${ACME_DIR}/acme.sh" --issue $DNSARG $DOMAINARG --home $ACME_DIR \
    --keylength ec-384 --keypath ${ACME_TEMP}/server.key --fullchainpath ${ACME_TEMP}/full.cer \
    --log /var/log/acme.log --reloadcmd "$RELOAD_CMD" \
    $INSECURE_FLAG $VERBOSE_FLAG $FORCE_FLAG $@

# package the acme directory
TAR_FILE="${ETC_DIR}/acme.tar.gz"
if [[ -f "$TAR_FILE" ]]; then
	mv -f "$TAR_FILE" "${TAR_FILE}.old"
fi

if [[ -d "$ACME_DIR" && -d "$ETC_DIR" ]]; then
    # shellcheck disable=SC2164
	( cd "$ETC_DIR"; tar czf "$TAR_FILE" "acme" )
fi

log "Starting gui service."
/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
