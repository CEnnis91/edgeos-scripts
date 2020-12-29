#!/bin/bash
# cfg_letsencrypt_cert.sh - request for and renew let's encrypt certificate
# https://github.com/hungnguyenm/edgemax-acme

if [[ 'vyattacfg' != "$(id -ng)" ]]; then
    exec sg vyattacfg -c "$0 $*"
fi

# shellcheck disable=SC1091
. "functions/vyatta.sh"

SUBDOMAIN="$1"
PROVIDER="$2"

# ensure the arguments are correct
if [[ -z "$SUBDOMAIN" || -z "$PROVIDER" || "$#" -lt 3 ]]; then
    echo "ERROR: invalid arguments"
    echo "$(basename "$0") <subdomain> <provider> [values]"
    exit 1
else
    shift; shift
    VALUES=( "$@" )
fi

# NOTE: not every provider has been tested, please read full documentation
# easily add other providers from here: https://github.com/acmesh-official/acme.sh/wiki/dnsapi
case "$PROVIDER" in
    # GENERATED with generate_acme_keys.sh, then tweaked
    1984hosting)    DNS="dns_1984hosting"; KEYS=( One984HOSTING_Password One984HOSTING_Username ) ;;
    acmedns)        DNS="dns_acmedns"; KEYS=( ACMEDNS_PASSWORD ACMEDNS_SUBDOMAIN ACMEDNS_UPDATE_URL ACMEDNS_USERNAME ) ;;
    acmeproxy)      DNS="dns_acmeproxy"; KEYS=( ACMEPROXY_ENDPOINT ACMEPROXY_PASSWORD ACMEPROXY_USERNAME ) ;;
    active24)       DNS="dns_active24"; KEYS=( ACTIVE24_Token ) ;;
    ad)             DNS="dns_ad"; KEYS=( AD_API_KEY ) ;;
    ali)            DNS="dns_ali"; KEYS=( Ali_Key Ali_Secret ) ;;
    anx)            DNS="dns_anx"; KEYS=( ANX_Token ) ;;
    arvan)          DNS="dns_arvan"; KEYS=( Arvan_Token ) ;;
    autodns)        DNS="dns_autodns"; KEYS=( AUTODNS_CONTEXT AUTODNS_PASSWORD AUTODNS_USER ) ;;
    aws)            DNS="dns_aws"; KEYS=( AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY ) ;;
    awsslow)        DNS="dns_aws"; KEYS=( AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DNS_SLOWRATE ) ;;
    azure)          DNS="dns_azure"; KEYS=( AZUREDNS_APPID AZUREDNS_CLIENTSECRET AZUREDNS_SUBSCRIPTIONID AZUREDNS_TENANTID ) ;;
    cf)             DNS="dns_cf"; KEYS=( CF_Account_ID CF_Token ) ;;
    cfzone)         DNS="dns_cf"; KEYS=( CF_Account_ID CF_Token CF_Zone_ID ) ;;
    clouddns)       DNS="dns_clouddns"; KEYS=( CLOUDDNS_CLIENT_ID CLOUDDNS_EMAIL CLOUDDNS_PASSWORD ) ;;
    cloudns)        DNS="dns_cloudns"; KEYS=( CLOUDNS_AUTH_PASSWORD CLOUDNS_SUB_AUTH_ID ) ;;
    cn)             DNS="dns_cn"; KEYS=( CN_Password CN_User ) ;;
    conoha)         DNS="dns_conoha"; KEYS=( CONOHA_IdentityServiceApi CONOHA_Password CONOHA_TenantId CONOHA_Username ) ;;
    constellix)     DNS="dns_constellix"; KEYS=( CONSTELLIX_Key CONSTELLIX_Secret ) ;;
    cx)             DNS="dns_cx"; KEYS=( CX_Key CX_Secret ) ;;
    cyon)           DNS="dns_cyon"; KEYS=( CY_OTP_Secret CY_Password CY_Username ) ;;
    da)             DNS="dns_da"; KEYS=( DA_Api DA_Api_Insecure ) ;;
    ddnss)          DNS="dns_ddnss"; KEYS=( DDNSS_Token ) ;;
    desec)          DNS="dns_desec"; KEYS=( DEDYN_NAME DEDYN_TOKEN ) ;;
    dgon)           DNS="dns_dgon"; KEYS=( DO_API_KEY ) ;;
    dnsimple)       DNS="dns_dnsimple"; KEYS=( DNSimple_OAUTH_TOKEN ) ;;
    doapi)          DNS="dns_doapi"; KEYS=( DO_LETOKEN ) ;;
    do)             DNS="dns_do"; KEYS=( DO_PID DO_PW ) ;;
    domeneshop)     DNS="dns_domeneshop"; KEYS=( DOMENESHOP_Secret DOMENESHOP_Token ) ;;
    dp)             DNS="dns_dp"; KEYS=( DP_Id DP_Key ) ;;
    dpi)            DNS="dns_dpi"; KEYS=( DPI_Id DPI_Key ) ;;
    dreamhost)      DNS="dns_dreamhost"; KEYS=( DH_API_KEY ) ;;
    duckdns)        DNS="dns_duckdns"; KEYS=( DuckDNS_Token ) ;;
    durabledns)     DNS="dns_durabledns"; KEYS=( DD_API_Key DD_API_User ) ;;
    dyn)            DNS="dns_dyn"; KEYS=( DYN_Customer DYN_Password DYN_Username ) ;;
    dynu)           DNS="dns_dynu"; KEYS=( Dynu_ClientId Dynu_Secret ) ;;
    easydns)        DNS="dns_easydns"; KEYS=( EASYDNS_Key EASYDNS_Token ) ;;
    edgedns)        DNS="dns_edgedns"; KEYS=( AKAMAI_ACCESS_TOKEN AKAMAI_CLIENT_SECRET AKAMAI_CLIENT_TOKEN AKAMAI_HOST ) ;;
    euserv)         DNS="dns_euserv"; KEYS=( EUSERV_Password EUSERV_Username ) ;;
    exoscale)       DNS="dns_exoscale"; KEYS=( EXOSCALE_API_KEY EXOSCALE_SECRET_KEY ) ;;
    freedns)        DNS="dns_freedns"; KEYS=( FREEDNS_Password FREEDNS_User ) ;;
    gandi_livedns)  DNS="dns_gandi_livedns"; KEYS=( GANDI_LIVEDNS_KEY ) ;;
    gd)             DNS="dns_gd"; KEYS=( GD_Key GD_Secret ) ;;
    gdnsdk)         DNS="dns_gdnsdk"; KEYS=( GDNSDK_Password GDNSDK_Username ) ;;
    he)             DNS="dns_he"; KEYS=( HE_Password HE_Username ) ;;
    hetzner)        DNS="dns_hetzner"; KEYS=( HETZNER_Token ) ;;
    hexonet)        DNS="dns_hexonet"; KEYS=( Hexonet_Login Hexonet_Password ) ;;
    hostingde)      DNS="dns_hostingde"; KEYS=( HOSTINGDE_APIKEY HOSTINGDE_ENDPOINT ) ;;
    huaweicloud)    DNS="dns_huaweicloud"; KEYS=( HUAWEICLOUD_Password HUAWEICLOUD_ProjectID HUAWEICLOUD_Username ) ;;
    infoblox)       DNS="dns_infoblox"; KEYS=( Infoblox_Creds Infoblox_Server ) ;;
    infomaniak)     DNS="dns_infomaniak"; KEYS=( INFOMANIAK_API_TOKEN ) ;;
    internetbs)     DNS="dns_internetbs"; KEYS=( INTERNETBS_API_KEY INTERNETBS_API_PASSWORD ) ;;
    inwx)           DNS="dns_inwx"; KEYS=( INWX_Password INWX_Shared_Secret INWX_User ) ;;
    ispconfig)      DNS="dns_ispconfig"; KEYS=( ISPC_Api ISPC_Api_Insecure ISPC_Password ISPC_User ) ;;
    jd)             DNS="dns_jd"; KEYS=( JD_ACCESS_KEY_ID JD_ACCESS_KEY_SECRET JD_REGION ) ;;
    joker)          DNS="dns_joker"; KEYS=( JOKER_PASSWORD JOKER_USERNAME ) ;;
    kappernet)      DNS="dns_kappernet"; KEYS=( KAPPERNETDNS_Key KAPPERNETDNS_Secret ) ;;
    kas)            DNS="dns_kas"; KEYS=( KAS_Authdata KAS_Authtype KAS_Login ) ;;
    kinghost)       DNS="dns_kinghost"; KEYS=( KINGHOST_Password KINGHOST_Username ) ;;
    knot)           DNS="dns_knot"; KEYS=( KNOT_KEY KNOT_SERVER ) ;;
    leaseweb)       DNS="dns_leaseweb"; KEYS=( LSW_Key ) ;;
    linode)         DNS="dns_linode"; KEYS=( LINODE_API_KEY ) ;;
    linode_v4)      DNS="dns_linode_v4"; KEYS=( LINODE_V4_API_KEY ) ;;
    loopia)         DNS="dns_loopia"; KEYS=( LOOPIA_Api LOOPIA_Password LOOPIA_User ) ;;
    lua)            DNS="dns_lua"; KEYS=( LUA_Email LUA_Key ) ;;
    maradns)        DNS="dns_maradns"; KEYS=( MARA_DUENDE_PID_PATH MARA_ZONE_FILE ) ;;
    me)             DNS="dns_me"; KEYS=( ME_Key ME_Secret ) ;;
    miab)           DNS="dns_miab"; KEYS=( MIAB_Password MIAB_Server MIAB_Username ) ;;
    misaka)         DNS="dns_misaka"; KEYS=( Misaka_Key ) ;;
    mydnsjp)        DNS="dns_mydnsjp"; KEYS=( MYDNSJP_MasterID MYDNSJP_Password ) ;;
    namecheap)      DNS="dns_namecheap"; KEYS=( NAMECHEAP_API_KEY NAMECHEAP_SOURCEIP NAMECHEAP_USERNAME ) ;;
    namecom)        DNS="dns_namecom"; KEYS=( Namecom_Token Namecom_Username ) ;;
    namesilo)       DNS="dns_namesilo"; KEYS=( Namesilo_Key ) ;;
    nederhost)      DNS="dns_nederhost"; KEYS=( NederHost_Key ) ;;
    neodigit)       DNS="dns_neodigit"; KEYS=( NEODIGIT_API_TOKEN ) ;;
    netcup)         DNS="dns_netcup"; KEYS=( NC_Apikey NC_Apipw NC_CID ) ;;
    netlify)        DNS="dns_netlify"; KEYS=( NETLIFY_ACCESS_TOKEN ) ;;
    nic)            DNS="dns_nic"; KEYS=( NIC_ClientID NIC_ClientSecret NIC_Password NIC_Username ) ;;
    njalla)         DNS="dns_njalla"; KEYS=( NJALLA_Token ) ;;
    nm)             DNS="dns_nm"; KEYS=( NM_sha256 NM_user ) ;;
    nsd)            DNS="dns_nsd"; KEYS=( Nsd_Command Nsd_ZoneFile ) ;;
    nsone)          DNS="dns_nsone"; KEYS=( NS1_Key ) ;;
    nsupdate)       DNS="dns_nsupdate"; KEYS=( NSUPDATE_KEY NSUPDATE_SERVER NSUPDATE_ZONE ) ;;
    nw)             DNS="dns_nw"; KEYS=( NW_API_ENDPOINT NW_API_TOKEN ) ;;
    one)            DNS="dns_one"; KEYS=( ONECOM_KeepCnameProxy ONECOM_Password ONECOM_User ) ;;
    online)         DNS="dns_online"; KEYS=( ONLINE_API_KEY ) ;;
    openprovider)   DNS="dns_openprovider"; KEYS=( OPENPROVIDER_PASSWORDHASH OPENPROVIDER_USER ) ;;
    openstack)      DNS="dns_openstack"; KEYS=( OS_AUTH_URL OS_PASSWORD OS_PROJECT_DOMAIN_NAME OS_PROJECT_NAME OS_USER_DOMAIN_NAME OS_USERNAME ) ;;
    opnsense)       DNS="dns_opnsense"; KEYS=( OPNs_Api_Insecure OPNs_Host OPNs_Key OPNs_Port OPNs_Token ) ;;
    pdns)           DNS="dns_pdns"; KEYS=( PDNS_ServerId PDNS_Token PDNS_Ttl PDNS_Url ) ;;
    pleskxml)       DNS="dns_pleskxml"; KEYS=( pleskxml_pass pleskxml_uri pleskxml_user ) ;;
    pointhq)        DNS="dns_pointhq"; KEYS=( PointHQ_Email ) ;;
    rackspace)      DNS="dns_rackspace"; KEYS=( RACKSPACE_Apikey RACKSPACE_Username ) ;;
    rcode0)         DNS="dns_rcode0"; KEYS=( RCODE0_API_TOKEN RCODE0_TTL RCODE0_URL ) ;;
    regru)          DNS="dns_regru"; KEYS=( REGRU_API_Password REGRU_API_Username ) ;;
    schlundtech)    DNS="dns_schlundtech"; KEYS=( SCHLUNDTECH_PASSWORD SCHLUNDTECH_USER ) ;;
    selectel)       DNS="dns_selectel"; KEYS=( SL_Key ) ;;
    servercow)      DNS="dns_servercow"; KEYS=( SERVERCOW_API_Password SERVERCOW_API_Username ) ;;
    tele3)          DNS="dns_tele3"; KEYS=( TELE3_Key TELE3_Secret ) ;;
    transip)        DNS="dns_transip"; KEYS=( TRANSIP_Key_File TRANSIP_Username ) ;;
    ultra)          DNS="dns_ultra"; KEYS=( ULTRA_PWD ULTRA_USR ) ;;
    unoeuro)        DNS="dns_unoeuro"; KEYS=( UNO_Key UNO_User ) ;;
    variomedia)     DNS="dns_variomedia"; KEYS=( VARIOMEDIA_API_TOKEN ) ;;
    vscale)         DNS="dns_vscale"; KEYS=( VSCALE_API_KEY ) ;;
    vultr)          DNS="dns_vultr"; KEYS=( VULTR_API_KEY ) ;;
    world4you)      DNS="dns_world4you"; KEYS=( WORLD4YOU_PASSWORD WORLD4YOU_USERNAME ) ;;
    yandex)         DNS="dns_yandex"; KEYS=( PDD_Token ) ;;
    zilore)         DNS="dns_zilore"; KEYS=( Zilore_Key ) ;;
    zone)           DNS="dns_zone"; KEYS=( ZONE_Key ZONE_Username ) ;;
    zonomi)         DNS="dns_zonomi"; KEYS=( ZM_Key ) ;;
    # END GENERATED section

    # https://github.com/acmesh-official/acme.sh/wiki/How-to-use-OVH-domain-api
    ovh)            DNS="dns_ovh"; KEYS=( OVH_AK OVH_AS ) ;;

    *)              echo "ERROR: Unknown provider '${PROVIDER}'"
                    exit 2
                    ;;
esac

PARENT_DIR="$(dirname "$(readlink -f "$0")")"
GUI_SERVER_PEM="/config/ssl/server.pem"
LETS_ENCRYPT="${PARENT_DIR}/lets_encrypt"
RENEW_ACME="${LETS_ENCRYPT}/renew_acme.sh"
RENEWAL_ARGS="-d ${SUBDOMAIN} -n ${DNS}"
RENEW_TASK="renew.${SUBDOMAIN}"

index=0
for key in "${KEYS[@]}"; do
    value="${VALUES[${index}]}"
    index=$((index+1))

    if [[ -n "$key" && -n "$value" ]]; then
        RENEWAL_ARGS="${RENEWAL_ARGS} -t ${key} -k ${VALUES[${index}]}"
    else
        echo "ERROR: Invalid key-value pair '${key}:${value}'"
        exit 3
    fi
done

echo "INFO: Requesting initial certificate"
"${RENEW_ACME} ${RENEWAL_ARGS}"

RESULT="$?"
if [[ "$RESULT" != "0" ]]; then
    echo "ERROR: There was an issue when requesting the initial certificate"
    exit $RESULT
fi

if check_config "service gui cert-file"; then
    echo "INFO: service gui cert-file already exists in the config"
    exec_config "show service gui cert-file"
else
    echo "INFO: Adding gui cert-file to the config"
    exec_config "set service gui cert-file ${GUI_SERVER_PEM}"
fi

if check_config "system task-scheduler task ${RENEW_TASK}"; then
    echo "INFO: system task-scheduler task '${RENEW_TASK}' already exists in the config"
    exec_config "show system task-scheduler task ${RENEW_TASK}"
    exit 0
fi

SCRIPT=$(cat <<EOF
    # set renewal task
    set system task-scheduler task $RENEW_TASK executable path $RENEW_ACME
    set system task-scheduler task $RENEW_TASK interval 1d
    set system task-scheduler task $RENEW_TASK executable arguments "$RENEWAL_ARGS"
    commit
EOF
)

echo "INFO: Adding renewal task to the config"
exec_config "$SCRIPT"
