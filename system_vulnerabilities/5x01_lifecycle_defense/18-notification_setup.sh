#!/bin/bash
# Configure unattended-upgrades audit logging and local notifications.
set -u

printf '%s\n\n' '=== Notification Configuration ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: notification configuration requires root privileges.'
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

if ! set_option 'Unattended-Upgrade::Mail' 'root' ||
   ! set_option 'Unattended-Upgrade::MailOnlyOnError' 'false' ||
   ! set_option 'Unattended-Upgrade::MailReport' 'on-change' ||
   ! set_option 'Unattended-Upgrade::SyslogEnable' 'true' ||
   ! set_option 'Unattended-Upgrade::SyslogFacility' 'daemon'; then
    printf '%s\n' 'ERROR: could not write notification settings.'
    exit 1
fi

log_dir=/var/log/unattended-upgrades
log_one="$log_dir/unattended-upgrades.log"
log_two="$log_dir/unattended-upgrades-dpkg.log"
if ! mkdir -p "$log_dir" || ! touch "$log_one" "$log_two"; then
    printf '%s\n' 'ERROR: could not create unattended-upgrades logs.'
    exit 1
fi
chmod 0640 "$log_one" "$log_two"

printf '%s\n' 'Email settings:'
printf '  Mail::OnlyOnError: "false"\n'
printf '  Mail::Report: "on-change"\n'
printf '  Recipient: root (local delivery)\n\n'
printf '%s\n' 'Logging settings:'
printf '  Syslog::Enable: "true"\n'
printf '  Syslog::Facility: "daemon"\n\n'
printf '%s\n' 'Log locations:'
printf '  %s\n' "$log_one"
printf '  %s\n\n' "$log_two"
printf '%s\n' 'Notification system configured.'
printf '%s\n' 'All update activity will be logged and reported.'
