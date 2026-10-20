#!/bin/bash
set -u

printf '%s\n\n' '=== Service Minimization ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then printf '%s\n' 'ERROR: service minimization requires root privileges.'; exit 1; fi
if ! command -v systemctl >/dev/null 2>&1; then printf '%s\n' 'ERROR: systemctl is required.'; exit 1; fi

services=('cups.service|Printing' 'avahi-daemon.service|mDNS' 'bluetooth.service|Bluetooth')
found=()
printf '%s\n\n' 'Checking for unnecessary services...'
printf '%s\n' 'Unnecessary services found:'
for entry in "${services[@]}"; do
    service=${entry%%|*}; purpose=${entry#*|}
    if systemctl list-unit-files "$service" --no-legend 2>/dev/null | grep -q "$service" || systemctl is-active --quiet "$service" 2>/dev/null; then
        found+=("$service|$purpose")
        printf '  %s (%s) - Not needed on web server\n' "$service" "$purpose"
    fi
done
if ((${#found[@]} == 0)); then printf '  None detected\n'; fi

printf '\n%s\n' 'Disabling services...'
failed=0
for entry in "${found[@]}"; do
    service=${entry%%|*}
    if systemctl disable --now "$service" >/dev/null 2>&1; then printf '  %s: Disabled and stopped\n' "$service"; else printf '  %s: FAILED\n' "$service"; failed=1; fi
done
if ((${#found[@]} == 0)); then printf '  Nothing to disable\n'; fi

printf '\n%s\n' 'Essential services preserved:'
essential_failed=0
check_service() {
    local label=$1; shift; local service
    for service in "$@"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then printf '  %s: Running ✓\n' "$label"; return 0; fi
    done
    printf '  %s: Not running or unavailable\n' "$label"
    essential_failed=1
}
check_service 'sshd.service' sshd.service ssh.service
check_service 'apache2.service' apache2.service nginx.service

if (( ! failed )); then
    printf '\n%s\n' 'Services reduced. Attack surface minimized.'
    (( essential_failed )) && exit 1
    exit 0
fi
printf '\n%s\n' 'Service minimization incomplete.'
exit 1

