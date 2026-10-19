#!/bin/bash
set -u

printf '%s\n\n' '=== Enabling SYN Cookies ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: enabling SYN cookies requires root privileges.'
    exit 1
fi
command -v sysctl >/dev/null 2>&1 || { printf '%s\n' 'ERROR: sysctl is required.'; exit 1; }

current=$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null || printf 'unknown')
printf '%s\n' 'Current state:'
printf '  net.ipv4.tcp_syncookies = %s\n\n' "$current"
printf '%s\n' 'Enabling SYN cookies...'
sysctl -w net.ipv4.tcp_syncookies=1 >/dev/null || exit 1
printf '  net.ipv4.tcp_syncookies = 1\n\n'

config=/etc/sysctl.d/99-hardening.conf
if [[ -f "$config" ]]; then
    backup="${config}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -p -- "$config" "$backup" || exit 1
fi
tmp=$(mktemp "${config}.tmp.XXXXXX") || exit 1
[[ -f "$config" ]] && cp -- "$config" "$tmp"
awk -v key='net.ipv4.tcp_syncookies' '
    BEGIN { changed=0 }
    $0 !~ /^[[:space:]]*#/ && $1 ~ ("^" key "=") {
        if (!changed) { print key "=1"; changed=1 }
        next
    }
    { print }
    END { if (!changed) print key "=1" }
' "$tmp" > "${tmp}.next" || { rm -f -- "$tmp" "${tmp}.next"; exit 1; }
mv -- "${tmp}.next" "$tmp"
chmod 0644 "$tmp"
mv -- "$tmp" "$config" || exit 1
printf '%s\n' 'Configuration saved to /etc/sysctl.d/99-hardening.conf'

sysctl -p "$config" >/dev/null 2>&1 || exit 1
if [[ "$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null)" == 1 ]]; then
    printf '\n%s\n' 'SYN flood protection: ENABLED'
    exit 0
fi
printf '\n%s\n' 'SYN flood protection: NOT ENABLED'
exit 1

