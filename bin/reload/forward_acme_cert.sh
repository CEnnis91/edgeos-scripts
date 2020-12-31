#!/bin/bash
# forward_acme_cert.sh - scp the new certificate to another server

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$(dirname "$SELF_DIR")")"

# shellcheck disable=SC1090
. "${ROOT_DIR}/lib/acme.sh"

usage() {
    echo "Usage: $0 -s <my.subdomain.com> -r <my.remotehost.com>" \
         "[-i identity_file] [-p remote_path] [-t certificate_type] [-u remote_user]" 1>&2; exit 1;
}

log() {
    if [ -z "$2" ]
    then
        printf -- "%s %s\n" "[$(date)]" "$1"
    fi
}

CERTIFICATE_TYPE="ecc"
IDENTITY_FILE="/root/.ssh/id_rsa"
REMOTE_PATH="/root/acme"
REMOTE_USER="root"

# first parse our options
while getopts ":hi:p:r:s:t:u:" opt; do
    case $opt in
        i) IDENTITY_FILE="$OPTARG";;
        p) REMOTE_PATH="$OPTARG";;
        r) REMOTE_HOST="$OPTARG";;
        s) SUBDOMAIN="$OPTARG";;
        t) CERTIFICATE_TYPE="$OPTARG";;
        u) REMOTE_USER="$OPTARG";;
        h | *)
          usage
          ;;
    esac
done
shift $((OPTIND -1))

# check for required parameters
if [ -z "$IDENTITY_FILE" ] || [ -z "$REMOTE_PATH" ] || [ -z "$REMOTE_HOST" ] \
        || [ -z "$SUBDOMAIN" ] || [ -z "$CERTIFICATE_TYPE" ] || [ -z "$REMOTE_USER" ]; then
    usage
fi

SUBDOMAIN_PATH="${SUBDOMAIN}_${CERTIFICATE_TYPE}"

log "Forwarding certificate to '${REMOTE_HOST}.'"
ssh -i "$IDENTITY_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_PATH}"

if [[ -d "${ACMEHOME}/${SUBDOMAIN_PATH}" ]]; then
    scp -i "$IDENTITY_FILE" "${ACME_DIR}/${SUBDOMAIN_PATH}/fullchain.cer" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/fullchain.pem"
    scp -i "$IDENTITY_FILE" "${ACME_DIR}/${SUBDOMAIN_PATH}/${SUBDOMAIN}.key" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/privkey.pem"
else
    echo "Directory '${ACME_DIR}/${SUBDOMAIN_PATH}' does not exist." 1>&2
    exit 1
fi
