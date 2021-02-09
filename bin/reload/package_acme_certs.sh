#!/bin/bash
# package_acme_certs.sh - tars let's encrypt certificates

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$(dirname "$SELF_DIR")")"

# shellcheck disable=SC1090
. "${ROOT_DIR}/lib/acme.sh"

TAR_FILE="${ETC_DIR}/acme.tar.gz"
if [[ -f "$TAR_FILE" ]]; then
	mv -f "$TAR_FILE" "${TAR_FILE}.old"
fi

if [[ -d "$ACME_DIR" ]]; then
	( cd "$ETC_DIR"; tar czf "$TAR_FILE" "acme" )
fi
