#!/bin/bash
# Configure unattended-upgrades automatic reboot behavior.
set -u

printf '%s\n\n' '=== Automatic Reboot Policy ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: reboot-policy configuration requires root privileges.'
    exit 1
fi

config=/etc/apt/apt.conf.d/50unattended-upgrades
mkdir -p "$(dirname "$config")" || exit 1
if [[ -f "$config" ]]; then
    backup="${config}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -p -- "$config" "$backup" || { printf '%s\n' 'ERROR: could not create configuration backup.'; exit 1; }
else
    : > "$config" || exit 1
fi

set_option() {
    local key=$1 value=$2 tmp
    tmp=$(mktemp "${config}.tmp.XXXXXX") || return 1
    awk -v key="$key" -v value="$value" '
        BEGIN { changed=0 }
        $0 !~ /^[[:space:]]*\/\// && $0 ~ "^[[:space:]]*" key "[[:space:]]" {
            if (!changed) { print key " \"" value "\";"; changed=1 }
            next
        }
        { print }
        END { if (!changed) print key " \"" value "\";" }
    ' "$config" > "$tmp" || { rm -f -- "$tmp"; return 1; }
    chmod 0644 "$tmp"
    mv -- "$tmp" "$config"
}

printf '%s\n\n' 'Configuring /etc/apt/apt.conf.d/50unattended-upgrades...'
if ! set_option 'Unattended-Upgrade::Automatic-Reboot' 'true' ||
   ! set_option 'Unattended-Upgrade::Automatic-Reboot-Time' '04:00' ||
   ! set_option 'Unattended-Upgrade::Automatic-Reboot-WithUsers' 'false'; then
    printf '%s\n' 'ERROR: could not write reboot policy.'
    exit 1
fi

printf '%s\n' 'Reboot settings:'
printf '  Automatic-Reboot: "true"\n'
printf '  Automatic-Reboot-Time: "04:00"\n'
printf '  Automatic-Reboot-WithUsers: "false"\n\n'
printf '%s\n' 'Additional safeguards:'
printf '  Reboot only when required (kernel/libc updates)\n'
printf '  Skip reboot if users are logged in\n\n'
printf '%s\n' 'Reboot policy configured.'
printf '%s\n' 'System will auto-reboot at 04:00 when required.'
