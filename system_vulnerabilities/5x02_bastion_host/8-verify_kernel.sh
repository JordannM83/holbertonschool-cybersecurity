#!/bin/bash
# Verify runtime kernel hardening and persistence.
set -u

printf '%s\n\n' '=== Kernel Hardening Verification ==='
passed=0
total=0
check() {
    local key=$1 expected=$2
    actual=$(sysctl -n "$key" 2>/dev/null || printf 'unavailable')
    total=$((total + 1))
    if [[ "$actual" == "$expected" ]]; then
        printf '  [PASS] %s = %s\n' "$key" "$actual"
        passed=$((passed + 1))
    else
        printf '  [FAIL] %s = %s (expected %s)\n' "$key" "$actual" "$expected"
    fi
}

if ! command -v sysctl >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: sysctl is required.'
    exit 1
fi

printf '%s\n' 'IP Forwarding:'
check net.ipv4.ip_forward 0
check net.ipv6.conf.all.forwarding 0
printf '\n%s\n' 'ICMP Redirects:'
check net.ipv4.conf.all.accept_redirects 0
check net.ipv4.conf.all.send_redirects 0
check net.ipv4.conf.default.accept_redirects 0
check net.ipv4.conf.default.send_redirects 0
printf '\n%s\n' 'Reverse Path Filtering:'
check net.ipv4.conf.all.rp_filter 1
printf '\n%s\n' 'SYN Cookies:'
check net.ipv4.tcp_syncookies 1
printf '\n%s\n' 'Source Routing:'
check net.ipv4.conf.all.accept_source_route 0
printf '\n%s\n' 'ICMP Configuration:'
check net.ipv4.icmp_echo_ignore_broadcasts 1
printf '\n%s\n' 'Persistence Check:'
total=$((total + 1))
if [[ -f /etc/sysctl.d/99-hardening.conf ]]; then
    printf '  [PASS] /etc/sysctl.d/99-hardening.conf exists\n'
    passed=$((passed + 1))
else
    printf '  [FAIL] /etc/sysctl.d/99-hardening.conf missing\n'
fi

printf '\nSummary: %s/%s checks passed\n' "$passed" "$total"
if [[ "$passed" -eq "$total" ]]; then
    printf '%s\n' 'Kernel hardening: COMPLETE'
    exit 0
fi
printf '%s\n' 'Kernel hardening: INCOMPLETE'
exit 1
