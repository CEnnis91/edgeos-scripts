#!/bin/bash
# acme_reload.sh - moves certificates to the proper location for web gui
# based on https://github.com/hungnguyenm/edgemax-acme

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$SELF_DIR")"
SSL_DIR="${ROOT_DIR}/secure/ssl"

BASE_DIR="${1:-/tmp}"
mkdir -p "$SSL_DIR"

if [[ -e "${BASE_DIR}/server.key" && -e "${BASE_DIR}/full.cer" ]]; then
    cat "${BASE_DIR}/server.key" "${BASE_DIR}/full.cer" > "${SSL_DIR}/server.pem"
    rm -rf "${BASE_DIR}"
fi
