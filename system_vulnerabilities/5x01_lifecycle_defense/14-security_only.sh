#!/bin/bash
# Restrict unattended-upgrades to security origins.
set -u

printf '%s\n\n' '=== Security-Only Configuration ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: security-only configuration requires root privileges.'
    exit 1
fi

config=/etc/apt/apt.conf.d/50unattended-upgrades
mkdir -p "$(dirname "$config")" || exit 1
if [[ -f "$config" ]]; then
    backup="${config}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -p -- "$config" "$backup" || { printf '%s\n' 'ERROR: could not create configuration backup.'; exit 1; }
fi
tmp=$(mktemp "${config}.tmp.XXXXXX") || exit 1
trap 'rm -f -- "$tmp"' EXIT

printf '%s\n' 'Configuring /etc/apt/apt.conf.d/50unattended-upgrades...'
if [[ -f "$config" ]] && grep -Eq '^[[:space:]]*Unattended-Upgrade::Allowed-Origins[[:space:]]*\{' "$config"; then
    awk '
        BEGIN { skipping=0 }
        /^[[:space:]]*Unattended-Upgrade::Allowed-Origins[[:space:]]*\{/ {
            print "Unattended-Upgrade::Allowed-Origins {"
            print "  \"${distro_id}:${distro_codename}-security\";"
            print "  \"${distro_id}ESMApps:${distro_codename}-apps-security\";"
            print "  \"${distro_id}ESM:${distro_codename}-infra-security\";"
            print "};"
            skipping=1
            next
        }
        skipping && /^[[:space:]]*};/ { skipping=0; next }
        !skipping { print }
    ' "$config" > "$tmp"
else
    [[ -f "$config" ]] && cp -- "$config" "$tmp"
    printf '\nUnattended-Upgrade::Allowed-Origins {\n' >> "$tmp"
    printf '  "${distro_id}:${distro_codename}-security";\n' >> "$tmp"
    printf '  "${distro_id}ESMApps:${distro_codename}-apps-security";\n' >> "$tmp"
    printf '  "${distro_id}ESM:${distro_codename}-infra-security";\n' >> "$tmp"
    printf '};\n' >> "$tmp"
fi
chmod 0644 "$tmp"
if ! mv -- "$tmp" "$config"; then
    printf '%s\n' 'ERROR: could not write unattended-upgrades configuration.'
    exit 1
fi

printf '\n%s\n' 'Allowed-Origins:'
printf '  [ENABLED]  "${distro_id}:${distro_codename}-security"\n'
printf '  [ENABLED]  "${distro_id}ESMApps:${distro_codename}-apps-security"\n'
printf '  [ENABLED]  "${distro_id}ESM:${distro_codename}-infra-security"\n'
printf '  [DISABLED] "${distro_id}:${distro_codename}-updates"\n'
printf '  [DISABLED] "${distro_id}:${distro_codename}-backports"\n'

printf '\n%s\n' 'Security-only filter applied.'
printf '%s\n' 'Only security updates will be installed automatically.'
