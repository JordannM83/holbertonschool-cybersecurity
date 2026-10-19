#!/bin/bash
set -u

printf '%s\n\n' '=== Blocking ICMP Redirects ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: blocking redirects requires root privileges.'
    exit 1
fi
command -v sysctl >/dev/null 2>&1 || { printf '%s\n' 'ERROR: sysctl is required.'; exit 1; }

config=/etc/sysctl.d/99-hardening.conf
if [[ -f "$config" ]]; then
    backup="${config}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -p -- "$config" "$backup" || exit 1
fi

settings=(
    net.ipv4.conf.all.accept_redirects=0
    net.ipv4.conf.default.accept_redirects=0
    net.ipv6.conf.all.accept_redirects=0
    net.ipv6.conf.default.accept_redirects=0
    net.ipv4.conf.all.send_redirects=0
    net.ipv4.conf.default.send_redirects=0
)
printf '%s\n' 'Disabling redirect acceptance...'
for setting in "${settings[@]:0:4}"; do
    sysctl -w "$setting" >/dev/null || exit 1
    printf '  %s = 0\n' "${setting%%=*}"
done
printf '%s\n' 'Disabling redirect sending...'
for setting in "${settings[@]:4:2}"; do
    sysctl -w "$setting" >/dev/null || exit 1
    printf '  %s = 0\n' "${setting%%=*}"
done

tmp=$(mktemp "${config}.tmp.XXXXXX") || exit 1
[[ -f "$config" ]] && cp -- "$config" "$tmp"
for setting in "${settings[@]}"; do
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
mv -- "$tmp" "$config" || exit 1
printf '\n%s\n' 'Configuration saved to /etc/sysctl.d/99-hardening.conf'

sysctl -p "$config" >/dev/null 2>&1 || exit 1
blocked=1
for setting in "${settings[@]}"; do
    key=${setting%%=*}
    [[ "$(sysctl -n "$key" 2>/dev/null)" == 0 ]] || blocked=0
done
if ((blocked)); then printf '\n%s\n' 'ICMP redirects: BLOCKED'; exit 0; fi
printf '\n%s\n' 'ICMP redirects: NOT FULLY BLOCKED'
exit 1

