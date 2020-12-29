#!/bin/bash
# shellcheck disable=SC1090
# cfg_openvpn_server.sh - add openvpn server config
# https://help.ui.com/hc/en-us/articles/115015971688-EdgeRouter-OpenVPN-Server

if [[ 'vyattacfg' != "$(id -ng)" ]]; then
    exec sg vyattacfg -c "$0 $*"
fi

SELF_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(dirname "$SELF_DIR")"

. "${ROOT_DIR}/lib/openvpn.sh"
. "${ROOT_DIR}/lib/vyatta.sh"

INTERFACE="$1"
SUBNET="$2"
PORT="${3:-1194}"
NAME_SERVER="${4:-192.168.1.1}"
CERT_DIR="$5"

if [[ -z "$CERT_DIR" || ! -d "$CERT_DIR" ]]; then
    CERT_DIR="$(get_server_dir "$INTERFACE")"
fi

# ensure the arguments are correct
if [[ -z "$INTERFACE" || -z "$SUBNET" || -z "$PORT" || -z "$NAME_SERVER" || -z "$CERT_DIR" ]]; then
    echo "ERROR: invalid arguments"
    echo "$(basename "$0") <interface> <subnet> [port] [name server] [cert dir]"
    exit 1
fi

# ensure that cert files exist
FILES=( 'cacert.pem' 'dh.pem' 'server.key' 'server.pem' )
for file in "${FILES[@]}"; do
    if [[ ! -e "${CERT_DIR}/${file}" ]]; then
        echo "ERROR: file '${CERT_DIR}/${file}' is missing"
        exit 1
    fi
done

if check_config "interfaces openvpn $INTERFACE"; then
    echo "INFO: openvpn interface '${INTERFACE}' already exists in the config"
    exec_config "show interfaces openvpn $INTERFACE"
    exit 0
fi

# determine the proper WAN_LOCAL rule
WAN_LOCAL_MAX="$(exec_config "show firewall name WAN_LOCAL" | grep "rule" | grep -o "[0-9]\+" | tail -n 1)"
VPN_RULE="$((WAN_LOCAL_MAX + 10))"
DESCRIPTION="$(basename "$0" ".sh")-${INTERFACE}"

SCRIPT=$(cat <<EOF
    # add firewall rules
    set firewall name WAN_LOCAL rule $VPN_RULE action accept
    set firewall name WAN_LOCAL rule $VPN_RULE description "${DESCRIPTION}"
    set firewall name WAN_LOCAL rule $VPN_RULE destination port $PORT
    set firewall name WAN_LOCAL rule $VPN_RULE protocol udp

    # add openvpn server interface
    set interfaces openvpn $INTERFACE description $DESCRIPTION
    set interfaces openvpn $INTERFACE mode server
    set interfaces openvpn $INTERFACE server subnet $SUBNET
    set interfaces openvpn $INTERFACE server name-server $NAME_SERVER

    # add openvpn certificates and keys
    set interfaces openvpn $INTERFACE tls ca-cert-file ${CERT_DIR}/cacert.pem
    set interfaces openvpn $INTERFACE tls cert-file ${CERT_DIR}/server.pem
    set interfaces openvpn $INTERFACE tls key-file ${CERT_DIR}/server.key
    set interfaces openvpn $INTERFACE tls dh-file ${CERT_DIR}/dh.pem

    # add interface to dns forwarding (optional)
    set service dns forwarding listen-on $INTERFACE

    # add openvpn options (optional)
    set interfaces openvpn $INTERFACE openvpn-option "--port ${PORT}"
    set interfaces openvpn $INTERFACE openvpn-option --duplicate-cn
    set interfaces openvpn $INTERFACE openvpn-option "--user nobody"
    set interfaces openvpn $INTERFACE openvpn-option "--group nogroup"
    set interfaces openvpn $INTERFACE openvpn-option --persist-key
    set interfaces openvpn $INTERFACE openvpn-option --persist-tun
    set interfaces openvpn $INTERFACE openvpn-option "--cipher AES-256-CBC"

    # generate using /usr/sbin/openvpn --genkey --secret ta.key
    set interfaces openvpn $INTERFACE openvpn-option "--tls-auth ${CERT_DIR}/ta.key 0"

    commit
EOF
)

echo "INFO: Adding OpenVPN interface to the config"
echo "INFO: You must manually add your own routes after"
echo "INFO: Example: 'set interfaces openvpn $INTERFACE server push-route 192.168.1.0/24'"
exec_config "$SCRIPT"