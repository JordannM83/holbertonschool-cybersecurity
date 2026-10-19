#!/bin/bash
set -u

printf '%s\n\n' '=== Enabling Reverse Path Filtering ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: enabling reverse path filtering requires root privileges.'
    exit 1
fi
command -v sysctl >/dev/null 2>&1 || { printf '%s\n' 'ERROR: sysctl is required.'; exit 1; }

config=/etc/sysctl.d/99-hardening.conf
if [[ -f "$config" ]]; then
    backup="${config}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -p -- "$config" "$backup" || exit 1
fi
settings=(net.ipv4.conf.all.rp_filter=1 net.ipv4.conf.default.rp_filter=1)
printf '%s\n' 'Setting strict mode (1) for all interfaces...'
for setting in "${settings[@]}"; do
    sysctl -w "$setting" >/dev/null || exit 1
    printf '  %s = 1\n' "${setting%%=*}"
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
strict=1
for setting in "${settings[@]}"; do
    key=${setting%%=*}
    [[ "$(sysctl -n "$key" 2>/dev/null)" == 1 ]] || strict=0
done
if ((strict)); then
    printf '\n%s\n' 'Reverse path filtering: STRICT MODE'
    printf '%s\n' 'Spoofed packets will be dropped.'
    exit 0
fi
printf '\n%s\n' 'Reverse path filtering: NOT STRICT'
exit 1

