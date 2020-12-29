#!/bin/bash
# cfg_openvpn_server.sh - add openvpn server config
# https://help.ui.com/hc/en-us/articles/115015971688-EdgeRouter-OpenVPN-Server

if [[ 'vyattacfg' != "$(id -ng)" ]]; then
    exec sg vyattacfg -c "$0 $*"
fi

# shellcheck disable=SC1091
. "functions/vyatta.sh"

CERTDIR="$1"
INTERFACE="$2"
SUBNET="$3"
PORT="${4:-1194}"
NAME_SERVER="${5:-192.168.1.1}"

# ensure the arguments are correct
if [[ -z "$CERTDIR" || -z "$INTERFACE" || -z "$SUBNET" || -z "$PORT" || -z "$NAME_SERVER" ]]; then
    echo "ERROR: invalid arguments"
    echo "$(basename "$0") <certificate directory> <interface> <subnet> [port] [name server]"
    exit 1
fi

# ensure that cert files exist
FILES=( 'cacert.pem' 'dh.pem' 'server.key' 'server.pem' )
for file in "${FILES[@]}"; do
    if [[ ! -e "${CERTDIR}/${file}" ]]; then
        echo "ERROR: file '$(basename "${CERTDIR}/${file}")' is missing"
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
    set interfaces openvpn $INTERFACE tls ca-cert-file ${CERTDIR}/cacert.pem
    set interfaces openvpn $INTERFACE tls cert-file ${CERTDIR}/server.pem
    set interfaces openvpn $INTERFACE tls key-file ${CERTDIR}/server.key
    set interfaces openvpn $INTERFACE tls dh-file ${CERTDIR}/dh.pem

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
    set interfaces openvpn $INTERFACE openvpn-option "--tls-auth ${CERTDIR}/ta.key 0"

    commit
EOF
)

echo "INFO: Adding OpenVPN interface to the config"
echo "INFO: You must manually add your own routes after"
echo "INFO: Example: 'set interfaces openvpn $INTERFACE server push-route 192.168.1.0/24'"
exec_config "$SCRIPT"
