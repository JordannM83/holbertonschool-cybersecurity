#!/bin/bash
set -u

printf '%s\n\n' '=== ICMP Configuration ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: ICMP configuration requires root privileges.'
    exit 1
fi
command -v sysctl >/dev/null 2>&1 || { printf '%s\n' 'ERROR: sysctl is required.'; exit 1; }

settings=(net.ipv4.icmp_echo_ignore_broadcasts=1 net.ipv4.icmp_echo_ignore_all=0 net.ipv4.icmp_ignore_bogus_error_responses=1)
printf '%s\n' 'Disabling broadcast ping response (Smurf prevention)...'
sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1 >/dev/null || exit 1
printf '  net.ipv4.icmp_echo_ignore_broadcasts = 1\n\n'
printf '%s\n' 'Keeping unicast ping enabled for diagnostics.'
sysctl -w net.ipv4.icmp_echo_ignore_all=0 >/dev/null || exit 1
printf '  net.ipv4.icmp_echo_ignore_all = 0\n\n'
printf '%s\n' 'Ignoring bogus ICMP error responses...'
sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1 >/dev/null || exit 1
printf '  net.ipv4.icmp_ignore_bogus_error_responses = 1\n'

config=/etc/sysctl.d/99-hardening.conf
if [[ -f "$config" ]]; then
    backup="${config}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -p -- "$config" "$backup" || exit 1
fi
tmp=$(mktemp "${config}.tmp.XXXXXX") || exit 1
[[ -f "$config" ]] && cp -- "$config" "$tmp"
if ! grep -q 'ICMP policy' "$tmp" 2>/dev/null; then
    printf '\n# ICMP policy: block broadcast ping, retain unicast diagnostics.\n' >> "$tmp"
fi
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
broadcast=$(sysctl -n net.ipv4.icmp_echo_ignore_broadcasts 2>/dev/null || printf 0)
unicast=$(sysctl -n net.ipv4.icmp_echo_ignore_all 2>/dev/null || printf 1)
printf '\nBroadcast ping: '; [[ "$broadcast" == 1 ]] && printf 'DISABLED\n' || printf 'ENABLED\n'
printf 'Unicast ping: '; [[ "$unicast" == 0 ]] && printf 'ENABLED\n' || printf 'DISABLED\n'
[[ "$broadcast" == 1 && "$unicast" == 0 ]]

