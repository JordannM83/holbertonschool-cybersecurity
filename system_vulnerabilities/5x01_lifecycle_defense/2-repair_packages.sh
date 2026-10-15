#!/bin/bash
# Repair interrupted DPKG configuration and broken dependencies.
set -u

printf '%s\n\n' '=== Package Repair ==='

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: package repair requires root privileges.'
    exit 1
fi
if ! command -v dpkg >/dev/null 2>&1 || ! command -v apt-get >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: dpkg and apt-get are required.'
    exit 1
fi

repair_failed=0
printf '%s\n' 'Configuring interrupted packages...'
DEBIAN_FRONTEND=noninteractive dpkg --configure -a || repair_failed=1

printf '\n%s\n' 'Fixing broken dependencies...'
DEBIAN_FRONTEND=noninteractive apt-get -f install -y || repair_failed=1

half_configured=0
if command -v dpkg-query >/dev/null 2>&1; then
    half_configured=$(dpkg-query -W -f='${db:Status-Status}\n' 2>/dev/null |
        awk '$1 == "half-configured" {n++} END {print n+0}')
fi

broken=1
if apt-get check >/dev/null 2>&1; then
    broken=0
fi

printf '\n%s\n' 'Verification:'
printf '  Half-configured packages: %s\n' "$half_configured"
printf '  Broken dependencies: %s\n' "$broken"

if [[ "$repair_failed" -eq 0 && "$half_configured" -eq 0 && "$broken" -eq 0 ]]; then
    printf '\n%s\n' 'Package database: CONSISTENT'
    exit 0
fi

printf '\n%s\n' 'Package database: INCONSISTENT'
exit 1
