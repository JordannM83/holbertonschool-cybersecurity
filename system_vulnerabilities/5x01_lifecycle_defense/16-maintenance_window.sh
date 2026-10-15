#!/bin/bash
# Schedule APT timers during the low-traffic maintenance window.
set -u

printf '%s\n\n' '=== Maintenance Window Configuration ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: maintenance-window configuration requires root privileges.'
    exit 1
fi
if ! command -v systemctl >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: systemctl is required.'
    exit 1
fi

printf '%s\n\n' 'Configuring systemd timer overrides...'

write_override() {
    local timer=$1 calendar=$2 delay=$3 directory=/etc/systemd/system/${1}.timer.d
    local file="$directory/override.conf" tmp backup
    mkdir -p "$directory" || return 1
    if [[ -f "$file" ]]; then
        backup="${file}.backup.$(date +%Y%m%d-%H%M%S)"
        cp -p -- "$file" "$backup" || return 1
    fi
    tmp=$(mktemp "${file}.tmp.XXXXXX") || return 1
    printf '[Timer]\nOnCalendar=\nOnCalendar=%s\nRandomizedDelaySec=%s\n' "$calendar" "$delay" > "$tmp"
    chmod 0644 "$tmp"
    mv -- "$tmp" "$file"
}

if ! write_override apt-daily '*-*-* 02:00' 30min; then
    printf '%s\n' 'ERROR: could not configure apt-daily.timer.'
    exit 1
fi
printf '%s\n' 'apt-daily.timer:'
printf '  OnCalendar: *-*-* 02:00\n'
printf '  RandomizedDelaySec: 30min\n\n'

if ! write_override apt-daily-upgrade '*-*-* 03:00' 60min; then
    printf '%s\n' 'ERROR: could not configure apt-daily-upgrade.timer.'
    exit 1
fi
printf '%s\n' 'apt-daily-upgrade.timer:'
printf '  OnCalendar: *-*-* 03:00\n'
printf '  RandomizedDelaySec: 60min\n\n'

printf '%s\n' 'Timer configuration:'
printf '  Package list update: 02:00-02:30\n'
printf '  Package installation: 03:00-04:00\n\n'

printf '%s\n' 'Reloading systemd...'
if ! systemctl daemon-reload; then
    printf '%s\n' 'ERROR: systemd daemon reload failed.'
    exit 1
fi
printf '%s\n' 'Maintenance window configured.'
