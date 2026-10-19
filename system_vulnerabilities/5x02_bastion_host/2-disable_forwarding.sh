#!/bin/bash
set -u

printf '%s\n\n' '=== Disabling IP Forwarding ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: disabling forwarding requires root privileges.'
    exit 1
fi
if ! command -v sysctl >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: sysctl is required.'
    exit 1
fi
ipv4=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || printf 'unknown')
ipv6=$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null || printf 'unknown')
printf '%s\n' 'Current state:'
printf '  net.ipv4.ip_forward = %s\n' "$ipv4"
printf '  net.ipv6.conf.all.forwarding = %s\n\n' "$ipv6"
printf '%s\n' 'Applying changes...'
if ! sysctl -w net.ipv4.ip_forward=0 >/dev/null || ! sysctl -w net.ipv6.conf.all.forwarding=0 >/dev/null; then
    printf '%s\n' 'ERROR: could not apply runtime forwarding settings.'
    exit 1
fi
printf '  net.ipv4.ip_forward = 0\n'
printf '  net.ipv6.conf.all.forwarding = 0\n\n'

config=/etc/sysctl.d/99-hardening.conf
if [[ -f "$config" ]]; then
    backup="${config}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -p -- "$config" "$backup" || exit 1
fi
tmp=$(mktemp "${config}.tmp.XXXXXX") || exit 1
if [[ -f "$config" ]]; then cp -- "$config" "$tmp"; fi
for setting in 'net.ipv4.ip_forward=0' 'net.ipv6.conf.all.forwarding=0'; do
    key=${setting%%=*}; value=${setting#*=}
    awk -v key="$key" -v value="$value" '
        BEGIN { changed=0 }
        $0 !~ /^[[:space:]]*#/ && $1 ~ ("^" key "=") {
            if (!changed) { print key "=" value; changed=1 }
            next
        }
        { print }
        END { if (!changed) print key "=" value }
    ' "$tmp" > "${tmp}.next" || { rm -f -- "$tmp" "${tmp}.next"; exit 1; }
    mv -- "${tmp}.next" "$tmp"
done
chmod 0644 "$tmp"
if ! mv -- "$tmp" "$config"; then
    rm -f -- "$tmp"
    printf '%s\n' 'ERROR: could not persist sysctl configuration.'
    exit 1
fi
printf '%s\n' 'Making persistent in /etc/sysctl.d/99-hardening.conf...'
sysctl -p "$config" >/dev/null 2>&1 || { printf '%s\n' 'ERROR: sysctl rejected the persistent configuration.'; exit 1; }
verified4=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || printf 'unknown')
verified6=$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null || printf 'unknown')
printf '\n%s\n' 'Verification:'
if [[ "$verified4" == 0 ]]; then printf '  IPv4 forwarding: DISABLED\n'; else printf '  IPv4 forwarding: ENABLED\n'; fi
if [[ "$verified6" == 0 ]]; then printf '  IPv6 forwarding: DISABLED\n'; else printf '  IPv6 forwarding: ENABLED\n'; fi
[[ "$verified4" == 0 && "$verified6" == 0 ]]

