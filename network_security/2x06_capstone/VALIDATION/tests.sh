#!/bin/bash
# tests.sh - Automated compliance checks for LogiCorp Gateway
# Verifies that all hardening steps from HARDENING/ have been applied correctly.
# Run as root. Each check prints [PASS] or [FAIL] and a final score.

set -uo pipefail

# config.sh has no fixed administrator name; set this in the environment when
# the approved account differs from the project default.
: "${EXPECTED_SUDO_USERS:=admin}"

# Load expected values from the hardening config so both scripts stay in sync
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../HARDENING/config.sh"

PASS=0
FAIL=0

# Helper: run a command silently and print [PASS] or [FAIL] with the description
check() {
    local description="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "[PASS] $description"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] $description"
        FAIL=$((FAIL + 1))
    fi
}

# Helper: check that a string does NOT appear in a command's output
check_absent() {
    local description="$1"
    local pattern="$2"
    shift 2
    if "$@" 2>/dev/null | grep -q "$pattern"; then
        echo "[FAIL] $description"
        FAIL=$((FAIL + 1))
    else
        echo "[PASS] $description"
        PASS=$((PASS + 1))
    fi
}

check_no_unexpected_accepts() {
    local line
    have nft || return 1
    while IFS= read -r line; do
        [[ $line =~ accept ]] || continue
        # These are the only ACCEPT rules emitted by HARDENING/firewall.sh.
        if [[ ! $line =~ iifname\ "lo".*accept &&
              ! $line =~ oifname\ "lo".*accept &&
              ! $line =~ ct\ state\ established,related.*accept &&
              ! $line =~ udp\ dport\ $VPN_PORT.*accept &&
              ! $line =~ iifname\ "$VPN_INTERFACE".*ip\ saddr\ $IT_VPN_IP.*tcp\ dport\ $SSH_PORT.*accept &&
              ! $line =~ iifname\ "$VPN_INTERFACE".*ip\ saddr\ $FINANCE_VPN_IP.*tcp\ dport.*\{.*$FTP_CONTROL_PORT.*$FTP_PASSIVE_MIN-$FTP_PASSIVE_MAX.*\}.*accept &&
              ! $line =~ iifname\ "$VPN_INTERFACE".*ip\ saddr\ $DATABASE_VPN_IP.*tcp\ dport\ $DATABASE_PORT.*accept ]]; then
            return 1
        fi
    done < <(nft list ruleset 2>/dev/null)
}

echo "======================================================"
echo " LogiCorp Gateway - Compliance Check"
echo "======================================================"
echo ""

# ------------------------------------------------------
# Firewall checks
# We verify that nftables is running with the expected
# default-deny policy and that the required rules exist.
# ------------------------------------------------------
echo "--- Firewall ---"

check "Firewall default INPUT policy is DROP" \
    bash -c "nft list chain inet logicorp input 2>/dev/null | grep -q 'policy drop'"

check "Firewall default FORWARD policy is DROP" \
    bash -c "nft list chain inet logicorp forward 2>/dev/null | grep -q 'policy drop'"

check "Firewall default OUTPUT policy is DROP" \
    bash -c "nft list chain inet logicorp output 2>/dev/null | grep -q 'policy drop'"

check "WireGuard port $VPN_PORT is open in INPUT" \
    bash -c "nft list ruleset 2>/dev/null | grep -Eq 'udp dport $VPN_PORT accept'"

check "SSH port $SSH_PORT is restricted to the IT VPN address" \
    bash -c "nft list ruleset 2>/dev/null | grep -Eq 'iifname \"$VPN_INTERFACE\" ip saddr $IT_VPN_IP .*tcp dport $SSH_PORT accept'"

check "FTP control port $FTP_CONTROL_PORT is restricted to the Finance VPN address" \
    bash -c "nft list ruleset 2>/dev/null | grep -Eq 'iifname \"$VPN_INTERFACE\" ip saddr $FINANCE_VPN_IP .*tcp dport.*$FTP_CONTROL_PORT.*accept'"

check "FTP passive port range is configured in the firewall" \
    bash -c "nft list ruleset 2>/dev/null | grep -Eq 'tcp dport.*$FTP_PASSIVE_MIN-$FTP_PASSIVE_MAX.*accept'"

check "Database port $DATABASE_PORT is restricted to the database VPN address" \
    bash -c "nft list ruleset 2>/dev/null | grep -Eq 'iifname \"$VPN_INTERFACE\" ip saddr $DATABASE_VPN_IP .*tcp dport $DATABASE_PORT accept'"

check "Firewall has no unexpected ACCEPT rules" check_no_unexpected_accepts

check_absent "SSH port is NOT open directly from the internet" \
    "tcp dport $SSH_PORT accept" \
    bash -c "nft list chain inet logicorp input 2>/dev/null | grep -v 'ip saddr $IT_VPN_IP'"

echo ""

# ------------------------------------------------------
# Service checks
# SSH and VPN must be running. ttyd and openvscode-server
# must be stopped since they expose root shells in a browser.
# ------------------------------------------------------
echo "--- Services ---"

check "SSH is running" \
    pgrep sshd

check "FTP server (vsftpd) is running" \
    pgrep vsftpd

check "VPN interface $VPN_INTERFACE is UP" \
    wg show "$VPN_INTERFACE"

for service_name in $UNNECESSARY_SERVICES; do
    check_absent "${service_name} is NOT running" \
        "$service_name" \
        pgrep -a "$service_name"
done

check "Backdoor cron job has been removed" \
    bash -c "! test -f '$BACKDOOR_CRON'"

echo ""

# ------------------------------------------------------
# Access control checks
# Root login and password auth must be disabled in SSH.
# Anonymous FTP must be disabled.
# ------------------------------------------------------
echo "--- Access Control ---"

check "Root SSH login is disabled" \
    grep -Eq "^[[:space:]]*PermitRootLogin[[:space:]]+no([[:space:]]|$)" "$SSHD_CONFIG"

check "Password authentication is disabled (key-only)" \
    grep -Eq "^[[:space:]]*PasswordAuthentication[[:space:]]+no([[:space:]]|$)" "$SSHD_CONFIG"

check "SSH public-key authentication is enabled" \
    grep -Eq "^[[:space:]]*PubkeyAuthentication[[:space:]]+yes([[:space:]]|$)" "$SSHD_CONFIG"

check "SSH authentication methods are key-only" \
    grep -Eq "^[[:space:]]*AuthenticationMethods[[:space:]]+publickey([[:space:]]|$)" "$SSHD_CONFIG"

check_sudo_user() {
    local user="$1"
    id "$user" >/dev/null 2>&1 || return 1
    id -nG "$user" 2>/dev/null | tr ' ' '\n' | grep -Eq '^(sudo|wheel)$'
}

for user in $EXPECTED_SUDO_USERS; do
    check "Expected sudo user '$user' belongs to sudo/wheel" check_sudo_user "$user"
done

check "Anonymous FTP login is disabled" \
    grep -Eq "^[[:space:]]*anonymous_enable=NO([[:space:]]|$)" "$VSFTPD_CONFIG"

check "SSL is enabled on the FTP server" \
    grep -Eq "^[[:space:]]*ssl_enable=YES([[:space:]]|$)" "$VSFTPD_CONFIG"

check "FTP requires TLS for logins and data" \
    bash -c "grep -Eq '^[[:space:]]*force_local_logins_ssl=YES([[:space:]]|$)' '$VSFTPD_CONFIG' && grep -Eq '^[[:space:]]*force_local_data_ssl=YES([[:space:]]|$)' '$VSFTPD_CONFIG'"

check "FTP passive range matches the configured values" \
    bash -c "grep -Eq '^[[:space:]]*pasv_min_port=$FTP_PASSIVE_MIN([[:space:]]|$)' '$VSFTPD_CONFIG' && grep -Eq '^[[:space:]]*pasv_max_port=$FTP_PASSIVE_MAX([[:space:]]|$)' '$VSFTPD_CONFIG'"

echo ""

# ------------------------------------------------------
# Network configuration checks
# IP forwarding must be on so VPN clients can reach
# internal networks through the gateway.
# ------------------------------------------------------
echo "--- Network Configuration ---"

check "IP forwarding is enabled" \
    bash -c "sysctl net.ipv4.ip_forward 2>/dev/null | grep -q '= 1'"

check "VPN interface $VPN_INTERFACE has correct address" \
    bash -c "ip addr show '$VPN_INTERFACE' 2>/dev/null | grep -Eq 'inet[[:space:]]+$VPN_SERVER_ADDRESS/'"

check "VPN route $VPN_SUBNET uses $VPN_INTERFACE" \
    bash -c "ip route show '$VPN_SUBNET' 2>/dev/null | grep -Eq '(^|[[:space:]])dev[[:space:]]+$VPN_INTERFACE([[:space:]]|$)'"

check "Startup script no longer flushes firewall rules at boot" \
    bash -c "! grep -Eq '^[[:space:]]*nft[[:space:]]+flush[[:space:]]+ruleset' '$STARTUP_SCRIPT'"

check "Startup script loads firewall rules at boot" \
    grep -Fq "nft -f $NFTABLES_CONFIG" "$STARTUP_SCRIPT"

echo ""

# ------------------------------------------------------
# Final score
# ------------------------------------------------------
TOTAL=$((PASS + FAIL))
echo "======================================================"
echo " RESULT: $PASS/$TOTAL checks passed"
if [ "$FAIL" -gt 0 ]; then
    echo " $FAIL check(s) failed. Review the [FAIL] lines above."
    exit 1
else
    echo " All checks passed."
fi
echo "======================================================"
