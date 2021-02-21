#!/bin/bash
# shellcheck disable=SC2034
# globals.sh

__SELF_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
__ROOT_DIR="$(dirname "${__SELF_DIR}")"

BIN_DIR="${__ROOT_DIR}/bin"
ETC_DIR="${__ROOT_DIR}/etc"
LIB_DIR="${__ROOT_DIR}/lib"
SHARE_DIR="${__ROOT_DIR}/share"
UTIL_DIR="${__ROOT_DIR}/util"

FIRSTBOOT_D="${__ROOT_DIR}/firstboot.d"
POST_CONFIG_D="${__ROOT_DIR}/post-config.d"
PRE_CONFIG_D="${__ROOT_DIR}/pre-config.d"

# generate a help message right from comments in getopts
generate_getopts_help() {
    local file="$1"
    local opts_var="$2"
    local indent="${3:-20}"

    local optstring opts_case
    optstring="$(grep -o "while getopts.*${opts_var}" "$file")"
    optstring="$(echo "$optstring" | awk '{print $3}' | tr -d "'\"" | sed -r 's/([^:]?)(:?)/\1\2\n/g')"
    opts_case="$(sed -n "/case.*${opts_var}/,/esac$/p" "$file")"

    echo "Usage: $(basename "$file") [options]"
    for opt in $optstring; do
        # detect silent mode
        [[ "$opt" == ":" ]] && continue

        local arg_name=""
        local has_comment="^\s*\#.*"
        local has_arg="[[][^]]*[]]"

        local opt_help
        opt_help="$(echo "$opts_case" | grep -B 1 "^\s*${opt/:/}\s*[)]" | head -n1)"
        [[ ! $opt_help =~ $has_comment ]] && opt_help=""

        if [[ $opt =~ : && "$opt_help" =~ $has_arg ]]; then
            arg_name="$(echo "$opt_help" | grep -o "$has_arg")"
            # shellcheck disable=SC2001
            opt_help="$(echo "$opt_help" | sed "s/$has_arg//g")"
        fi

        opt_help="$(echo "${opt_help#*#}" | awk '{$1=$1};1')"
        printf "\t%s %-${indent}s%b\n" "-${opt/:/}" "$arg_name" "$opt_help"
    done
}
