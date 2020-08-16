#!/bin/vbash
# add_debian_packages - add other debian packages
# https://help.ui.com/hc/en-us/articles/205202560-EdgeRouter-Add-Debian-Packages-to-EdgeOS

# shellcheck shell=bash
if [[ 'vyattacfg' != "$(id -ng)" ]]; then
    exec sg vyattacfg -c "$0 $*"
fi

. functions.sh

if check_config "system package"; then
    echo "INFO: Debian packages already exist in the config"
    exec_config "show system package"
    exit 0
fi

DISTRO="stretch"
SCRIPT=$(cat <<EOF
    set system package repository $DISTRO components 'main contrib non-free'
    set system package repository $DISTRO distribution $DISTRO
    set system package repository $DISTRO url http://http.us.debian.org/debian
    commit
EOF
)

echo "INFO: Adding Debian packages to config"
exec_config "$SCRIPT"
