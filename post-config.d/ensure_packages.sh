#!/bin/bash
# ensure_packages.sh - ensure packages are installed
# https://community.ui.com/questions/cf737894-174c-4aef-8aed-ebcfe62f5cff

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$SELF_DIR")"

# shellcheck disable=SC1090
. "${ROOT_DIR}/lib/globals.sh"

PACKAGE_DIR="${SHARE_DIR}/packages"
mkdir -p "$PACKAGE_DIR"
PACKAGES="$(find "$PACKAGE_DIR" -name '*.deb')"

for package in $PACKAGES; do
    name="$(dpkg --info "$package" | grep "Package:" | cut -d' ' -f2-)"
    installed="$(dpkg-query -W --showformat='${Status}\n' "$package" | grep "installed")"

    if [[ -z "$installed" ]]; then
        echo "INFO: ${name} is not installed, installing"
        dpkg -i "$package"
    fi
done
