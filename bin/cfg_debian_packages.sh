#!/bin/bash
# cfg_debian_packages.sh - add other debian packages
# https://help.ui.com/hc/en-us/articles/205202560-EdgeRouter-Add-Debian-Packages-to-EdgeOS

# included from vyatta.sh for easier integration before git is installed
if [[ "$DEBUG" == "1" ]]; then
    CMD_WRAPPER="echo"
else
    CMD_WRAPPER="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper"

    if [[ ! -e "$CMD_WRAPPER" ]]; then
        echo "ERROR: cannot find vyatta-cfg-cmd-wrapper"
        exit 1
    else
        if [[ 'vyattacfg' != "$(id -ng)" ]]; then
            exec sg vyattacfg -c "$0 $*"
        fi
    fi
fi

check_config() {
    # shellcheck disable=SC2155
    local key="$*"

    # shellcheck disable=SC2086,SC2155
    local exists="$(exec_config show $key)"

    case $exists in
        *is\ empty)     return 1 ;;
        *not\ valid)    echo "$exists"; return 0 ;;
        *)              return $DEBUG ;;
    esac
}

exec_config() {
    # shellcheck disable=SC2155
    local commands="$*"

    "$CMD_WRAPPER" begin
    while read -r command; do
        if [[ -n "$command" && ! $command =~ ^[\ \t]*#.*$ ]]; then
            # shellcheck disable=SC2086
            eval "$CMD_WRAPPER" $command
        fi
    done < <(echo "$commands")
    "$CMD_WRAPPER" end
}

# ---

CODENAME="$(grep "VERSION_CODENAME" "/etc/os-release" | awk -F= '{print $2}')"
DISTRO="${1:-${CODENAME:-stretch}}"

SCRIPT=$(cat <<EOF
    set system package repository $DISTRO components 'main contrib non-free'
    set system package repository $DISTRO distribution $DISTRO
    set system package repository $DISTRO url http://http.us.debian.org/debian
    commit
EOF
)

if check_config "system package repository $DISTRO"; then
    SCRIPT="$(echo -e "delete system package repository ${DISTRO}\n${SCRIPT}")"
fi

echo "INFO: Adding Debian packages to the config"
exec_config "$SCRIPT"
