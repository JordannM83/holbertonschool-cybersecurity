#!/bin/bash
# Simulate unattended-upgrades without changing packages.
set -u

printf '%s\n\n' '=== Unattended-Upgrades Dry Run ==='
if ! command -v unattended-upgrade >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: unattended-upgrade is not installed.'
    exit 1
fi

printf '%s\n\n' 'Running simulation...'
simulation=$(unattended-upgrade --dry-run --debug 2>&1)
simulation_rc=$?

printf '%s\n' 'Packages that WOULD be upgraded:'
upgrades=$(printf '%s\n' "$simulation" | awk '
    /Packages that will be upgraded:/ {sub(/^.*: /, ""); print; found=1}
    /^Inst / {print $2; found=1}
')
upgrade_count=0
if [[ -n "$upgrades" ]]; then
    while IFS= read -r package; do
        [[ -n "$package" ]] || continue
        printf '  %s (security)\n' "$package"
        upgrade_count=$((upgrade_count + 1))
    done <<< "$upgrades"
else
    printf '  None\n'
fi

printf '\n%s\n' 'Packages PROTECTED by blacklist:'
blacklist=/etc/apt/apt.conf.d/50unattended-upgrades
blacklisted=$(sed -n '/Package-Blacklist[[:space:]]*{/,/};/p' "$blacklist" 2>/dev/null |
    sed -n 's/^[[:space:]]*"\([^"]*\)".*/\1/p')
blacklist_count=0
if [[ -n "$blacklisted" ]]; then
    while IFS= read -r package; do
        [[ -n "$package" ]] || continue
        printf '  %s (blacklisted - manual review required)\n' "$package"
        blacklist_count=$((blacklist_count + 1))
    done <<< "$blacklisted"
else
    printf '  None\n'
fi

printf '\n%s\n' 'Packages NOT in security origin:'
skipped=$(printf '%s\n' "$simulation" | grep -Ei 'not from a security|non-security|skipp' || true)
skipped_count=$(printf '%s\n' "$skipped" | awk 'NF {n++} END {print n+0}')
if [[ "$skipped_count" -gt 0 ]]; then
    printf '%s\n' "$skipped" | sed 's/^/  /'
else
    printf '  None detected\n'
fi

reboot='NO'
if printf '%s\n' "$simulation" | grep -Eiq 'linux-(image|headers)|reboot[[:space:]]+required'; then reboot='YES (kernel update)'; fi
printf '\n%s\n' 'Simulation summary:'
printf '  Would upgrade: %s packages\n' "$upgrade_count"
printf '  Blacklisted: %s packages\n' "$blacklist_count"
printf '  Skipped (non-security): %s packages\n' "$skipped_count"
printf '  Reboot required: %s\n\n' "$reboot"

if [[ "$simulation_rc" -eq 0 ]]; then
    printf '%s\n' 'Configuration validation: PASSED'
    exit 0
fi
printf '%s\n' 'Configuration validation: FAILED'
exit 1
