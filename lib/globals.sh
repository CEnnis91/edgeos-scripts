#!/bin/bash
# shellcheck disable=SC2034
# globals.sh

__SELF_DIR="$(dirname "$(readlink -f "$0")")"
__ROOT_DIR="$(dirname "$(dirname "${__SELF_DIR}")")"

BIN_DIR="${__ROOT_DIR}/bin"
ETC_DIR="${__ROOT_DIR}/etc"
LIB_DIR="${__ROOT_DIR}/lib"
SHARE_DIR="${__ROOT_DIR}/share"
UTIL_DIR="${__ROOT_DIR}/util"

FIRSTBOOT_D="${__ROOT_DIR}/firstboot.d"
POST_CONFIG_D="${__ROOT_DIR}/post-config.d"
PRE_CONFIG_D="${__ROOT_DIR}/pre-config.d"
