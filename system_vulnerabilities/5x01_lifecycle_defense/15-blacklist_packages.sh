#!/bin/bash
# Prevent critical services from being updated automatically.
set -u

printf '%s\n\n' '=== Package Blacklist Configuration ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: package blacklist configuration requires root privileges.'
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

printf '%s\n' 'Adding to Unattended-Upgrade::Package-Blacklist:'
for package in apache2 apache2-bin mysql-server 'mysql-server-*' nginx docker-ce; do
    printf '  + "%s"\n' "$package"
done

if [[ -f "$config" ]] && grep -Eq '^[[:space:]]*Unattended-Upgrade::Package-Blacklist[[:space:]]*\{' "$config"; then
    awk '
        BEGIN { skipping=0 }
        /^[[:space:]]*Unattended-Upgrade::Package-Blacklist[[:space:]]*\{/ {
            print "Unattended-Upgrade::Package-Blacklist {"
            print "  \"apache2\";"
            print "  \"apache2-bin\";"
            print "  \"mysql-server\";"
            print "  \"mysql-server-*\";"
            print "  \"nginx\";"
            print "  \"docker-ce\";"
            print "};"
            skipping=1
            next
        }
        skipping && /^[[:space:]]*};/ { skipping=0; next }
        !skipping { print }
    ' "$config" > "$tmp"
else
    [[ -f "$config" ]] && cp -- "$config" "$tmp"
    printf '\nUnattended-Upgrade::Package-Blacklist {\n' >> "$tmp"
    printf '  "apache2";\n  "apache2-bin";\n  "mysql-server";\n' >> "$tmp"
    printf '  "mysql-server-*";\n  "nginx";\n  "docker-ce";\n};\n' >> "$tmp"
fi
chmod 0644 "$tmp"
if ! mv -- "$tmp" "$config"; then
    printf '%s\n' 'ERROR: could not write package blacklist.'
    exit 1
fi

printf '\n%s\n' "Blacklist written to $config"
printf '\n%s\n' 'These packages will NOT be automatically upgraded.'
printf '%s\n' 'Manual review required for security updates.'
