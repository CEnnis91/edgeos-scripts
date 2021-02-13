#!/bin/bash
# update_web_cert.sh - moves certificates to the proper location for web gui
# based on https://github.com/hungnguyenm/edgemax-acme

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$(dirname "$SELF_DIR")")"

# shellcheck disable=SC1090
. "${ROOT_DIR}/lib/acme.sh"

# create the certificate for the web interface
BASE_DIR="${1:-/tmp}"
SSL_DIR="${ETC_DIR}/ssl"
mkdir -p "$SSL_DIR"

if [[ -e "${BASE_DIR}/server.key" && -e "${BASE_DIR}/full.cer" ]]; then
    cat "${BASE_DIR}/server.key" "${BASE_DIR}/full.cer" > "${SSL_DIR}/server.pem"
    rm -rf "${BASE_DIR}"
fi
