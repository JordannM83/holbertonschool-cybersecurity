#!/bin/bash
# Safely remove stale package-manager locks. This script never kills processes.
set -u

printf '%s\n\n' '=== DPKG Unlock Procedure ==='
printf '%s\n' 'Checking for active package operations...'

processes=''
if command -v pgrep >/dev/null 2>&1; then
    # pgrep is preferred because it checks the complete command line for apt/dpkg.
    processes=$(pgrep -af 'apt|dpkg|unattended-upgrade' 2>/dev/null || true)
else
    processes=$(ps -eo pid=,args= 2>/dev/null | awk '$2 ~ /(^|\/)(apt|apt-get|dpkg|unattended-upgrade)$/ {print}')
fi

apt_processes=$(printf '%s\n' "$processes" | awk '$0 ~ /(^|[[:space:]])(apt|apt-get|unattended-upgrade)([[:space:]]|$)/')
dpkg_processes=$(printf '%s\n' "$processes" | awk '$0 ~ /(^|[[:space:]])dpkg([[:space:]]|$)/')

if [[ -n "$apt_processes" ]]; then
    printf '%s\n' '  apt processes: ACTIVE'
    printf '%s\n' "$apt_processes" | sed 's/^/    /'
else
    printf '%s\n' '  apt processes: None'
fi
if [[ -n "$dpkg_processes" ]]; then
    printf '%s\n' '  dpkg processes: ACTIVE'
    printf '%s\n' "$dpkg_processes" | sed 's/^/    /'
else
    printf '%s\n' '  dpkg processes: None'
fi

if [[ -n "$apt_processes$dpkg_processes" ]]; then
    printf '\n%s\n' 'Package operations are active; no lock files were removed.'
    exit 1
fi

printf '\n%s\n' 'Removing stale lock files...'
locks=(/var/lib/dpkg/lock-frontend /var/lib/dpkg/lock)
removed=0
failed=0

for lock in "${locks[@]}"; do
    if [[ ! -e "$lock" ]]; then
        printf '  %s: Already absent\n' "$lock"
        continue
    fi

    held=0
    if command -v fuser >/dev/null 2>&1 && fuser -s "$lock" 2>/dev/null; then held=1; fi
    if (( ! held )) && command -v lsof >/dev/null 2>&1 && lsof -t -- "$lock" >/dev/null 2>&1; then held=1; fi
    if (( held )); then
        printf '  %s: NOT removed (held by a process)\n' "$lock"
        failed=1
    elif rm -f -- "$lock" 2>/dev/null && [[ ! -e "$lock" ]]; then
        printf '  %s: Removed\n' "$lock"
        removed=$((removed + 1))
    else
        printf '  %s: FAILED (permission denied or removal error)\n' "$lock"
        failed=1
    fi
done

printf '\n%s\n' 'Verification:'
remaining=0
for lock in "${locks[@]}"; do
    if [[ -e "$lock" ]]; then
        printf '  %s: STILL PRESENT\n' "$lock"
        remaining=1
    fi
done

if (( ! remaining && ! failed )); then
    printf '%s\n\n' '  Package operations: UNLOCKED'
    printf '%s\n' 'DPKG unlocked successfully.'
    exit 0
fi

printf '%s\n' '  Package operations: STILL LOCKED'
printf '%s\n' 'DPKG was not fully unlocked.'
exit 1
