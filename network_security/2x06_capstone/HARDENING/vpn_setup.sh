#!/bin/bash
set -euo pipefail
umask 077

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Run vpn_setup.sh as root.' >&2; exit 1; }

if ! command -v wg >/dev/null || ! command -v wg-quick >/dev/null; then
    apt-get update
    apt-get install -y wireguard-tools
fi

install -d -m 700 "$WIREGUARD_DIR"
if [[ ! -s $WG_PRIVATE_KEY ]]; then
    wg genkey | tee "$WG_PRIVATE_KEY" | wg pubkey > "$WG_PUBLIC_KEY"
    chmod 600 "$WG_PRIVATE_KEY" "$WG_PUBLIC_KEY"
fi

[[ ! -e $WG_CONFIG ]] || cp -a -- "$WG_CONFIG" "$WG_CONFIG.backup"
cat > "$WG_CONFIG" <<WG
[Interface]
Address = $VPN_SERVER_IP
ListenPort = $VPN_PORT
PrivateKey = $(<"$WG_PRIVATE_KEY")

# IT administrator: $IT_VPN_IP
#[Peer]
#PublicKey = PASTE_IT_PUBLIC_KEY
#AllowedIPs = $IT_VPN_IP/32

# Finance FTPS client: $FINANCE_VPN_IP
#[Peer]
#PublicKey = PASTE_FINANCE_PUBLIC_KEY
#AllowedIPs = $FINANCE_VPN_IP/32

# Authorized database client: $DATABASE_VPN_IP
#[Peer]
#PublicKey = PASTE_DATABASE_PUBLIC_KEY
#AllowedIPs = $DATABASE_VPN_IP/32
WG
chmod 600 "$WG_CONFIG"

cat > "$WG_CLIENT_TEMPLATE" <<WG
[Interface]
Address = CLIENT_VPN_IP/32
PrivateKey = CLIENT_PRIVATE_KEY

[Peer]
PublicKey = $(<"$WG_PUBLIC_KEY")
Endpoint = GATEWAY_PUBLIC_IP:$VPN_PORT
AllowedIPs = $VPN_SERVER_ADDRESS/32
PersistentKeepalive = 25
WG
chmod 600 "$WG_CLIENT_TEMPLATE"

printf '%s\n' 'net.ipv4.ip_forward=1' > "$SYSCTL_FORWARD_CONFIG"
sysctl -p "$SYSCTL_FORWARD_CONFIG"
if wg show "$VPN_INTERFACE" >/dev/null 2>&1; then
    wg syncconf "$VPN_INTERFACE" <(wg-quick strip "$WG_CONFIG")
else
    wg-quick up "$VPN_INTERFACE"
fi
systemctl enable "wg-quick@$VPN_INTERFACE" 2>/dev/null || true
echo "WireGuard is ready on $VPN_SERVER_IP; add and test a peer before firewall.sh."
