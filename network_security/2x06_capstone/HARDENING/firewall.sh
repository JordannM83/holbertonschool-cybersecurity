#!/bin/bash
set -euo pipefail
umask 077
export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Run firewall.sh as root.' >&2; exit 1; }
command -v at >/dev/null || { echo 'Install the at package before applying the firewall.' >&2; exit 1; }
wg show "$VPN_INTERFACE" >/dev/null || { echo 'WireGuard is not running; firewall not changed.' >&2; exit 1; }

rules_candidate=$(mktemp)
trap 'rm -f -- "$rules_candidate"' EXIT
cat > "$rules_candidate" <<RULES
flush ruleset
table inet logicorp {
 chain input {
  type filter hook input priority 0; policy drop;
  ct state invalid drop
  iifname "lo" accept
  ct state established,related accept
  udp dport $VPN_PORT accept
  iifname "$VPN_INTERFACE" ip saddr $IT_VPN_IP ip daddr $VPN_SERVER_ADDRESS tcp dport $SSH_PORT accept
  iifname "$VPN_INTERFACE" ip saddr $FINANCE_VPN_IP ip daddr $VPN_SERVER_ADDRESS tcp dport { $FTP_CONTROL_PORT, $FTP_PASSIVE_MIN-$FTP_PASSIVE_MAX } accept
  iifname "$VPN_INTERFACE" ip saddr $DATABASE_VPN_IP ip daddr $VPN_SERVER_ADDRESS tcp dport $DATABASE_PORT accept
  limit rate 5/second burst 20 packets log prefix "logicorp denied: " level warning
 }
 chain forward {
  type filter hook forward priority 0; policy drop;
 }
 chain output {
  type filter hook output priority 0; policy drop;
  oifname "lo" accept
  ct state established,related accept
 }
}
RULES
nft -c -f "$rules_candidate"

# Panic button is scheduled before the default-deny rules are applied.
panic_result=$(printf '%s\n' "$NFT_BIN flush ruleset" | at now + "$PANIC_DELAY" minutes 2>&1)
panic_job=$(sed -nE 's/.*job ([0-9]+).*/\1/p' <<< "$panic_result" | tail -n 1)
[[ -n $panic_job ]] || { echo "Unable to identify panic job: $panic_result" >&2; exit 1; }
printf '%s\n' "$panic_job" > "$PANIC_JOB_FILE"

install -m 600 "$rules_candidate" "$NFTABLES_CONFIG"
if ! nft -f "$NFTABLES_CONFIG"; then
    echo "Firewall application failed; panic job $panic_job remains armed." >&2
    exit 1
fi
echo "Firewall applied. Panic job $panic_job will flush it in $PANIC_DELAY minutes."
echo "After successful tests, cancel it with: atrm $panic_job"
