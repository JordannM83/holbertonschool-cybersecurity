#!/bin/bash
# Harden sshd_config safely and reload SSH only after validation.
set -u

printf '%s\n\n' '=== SSH Hardening ==='

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: SSH hardening requires root privileges.'
    exit 1
fi

config=/etc/ssh/sshd_config
if [[ ! -f "$config" ]]; then
    printf 'ERROR: %s was not found.\n' "$config"
    exit 1
fi
if ! command -v date >/dev/null 2>&1 || ! command -v cp >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: required file utilities are unavailable.'
    exit 1
fi

backup="${config}.backup.$(date +%Y%m%d)"
if [[ -e "$backup" ]]; then
    backup="${config}.backup.$(date +%Y%m%d-%H%M%S)"
fi
if ! cp -p -- "$config" "$backup"; then
    printf '%s\n' 'ERROR: could not create SSH configuration backup.'
    exit 1
fi
printf 'Backup created: %s\n\n' "$backup"

current_value() {
    awk -v key="$1" '$0 !~ /^[[:space:]]*#/ && $1 == key {print $2; exit}' "$config"
}

tmp=$(mktemp "${config}.tmp.XXXXXX") || {
    printf '%s\n' 'ERROR: could not create temporary configuration.'
    exit 1
}
cleanup() { rm -f -- "$tmp"; }
trap cleanup EXIT

set_option() {
    local key=$1 value=$2 old=$3
    awk -v key="$key" -v value="$value" '
        BEGIN { changed=0 }
        $0 !~ /^[[:space:]]*#/ && $1 == key {
            if (!changed) { print key " " value; changed=1 }
            next
        }
        { print }
        END { if (!changed) print key " " value }
    ' "$config" > "$tmp" || return 1
    chmod --reference="$config" "$tmp" 2>/dev/null || true
    chown --reference="$config" "$tmp" 2>/dev/null || true
    mv -- "$tmp" "$config" || return 1
    tmp=$(mktemp "${config}.tmp.XXXXXX") || return 1
    printf '  %s: %s -> %s\n' "$key" "${old:-unset}" "$value"
}

printf '%s\n' 'Applying hardening measures...'
for setting in \
    'PermitRootLogin|no' \
    'PasswordAuthentication|no' \
    'X11Forwarding|no' \
    'MaxAuthTries|3' \
    'ClientAliveInterval|300' \
    'ClientAliveCountMax|2'; do
    key=${setting%%|*}; value=${setting#*|}; old=$(current_value "$key")
    if ! set_option "$key" "$value" "$old"; then
        cp -p -- "$backup" "$config"
        printf '%s\n' 'ERROR: failed to update SSH configuration; backup restored.'
        exit 1
    fi
done

printf '\n%s\n' 'Configuration test:'
sshd_test=sshd
command -v "$sshd_test" >/dev/null 2>&1 || sshd_test=/usr/sbin/sshd
if ! "$sshd_test" -t -f "$config" 2>&1; then
    cp -p -- "$backup" "$config"
    printf '%s\n' '  FAILED; backup restored.'
    exit 1
fi
printf '  OK\n'

printf '\n%s\n' 'Reloading SSH service...'
reloaded=0
if command -v systemctl >/dev/null 2>&1; then
    if systemctl reload sshd.service 2>/dev/null || systemctl reload ssh.service 2>/dev/null; then reloaded=1; fi
elif command -v service >/dev/null 2>&1; then
    if service ssh reload >/dev/null 2>&1 || service sshd reload >/dev/null 2>&1; then reloaded=1; fi
fi
if ((reloaded)); then
    printf '  sshd.service: Reloaded\n\n'
else
    printf '  sshd.service: FAILED to reload\n'
    cp -p -- "$backup" "$config"
    exit 1
fi

printf '%s\n\n' 'SSH hardened successfully.'
printf '%s\n' 'WARNING: Ensure key-based authentication is configured'
printf '%s\n' '         before closing this session.'
