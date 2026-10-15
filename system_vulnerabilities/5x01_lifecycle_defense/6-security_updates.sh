#!/bin/bash
# Apply package upgrades from the distribution security pocket only.
set -u

printf '%s\n\n' '=== Security Updates ==='

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: applying security updates requires root privileges.'
    exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: apt-get is required.'
    exit 1
fi

codename=''
if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    codename=${VERSION_CODENAME:-}
fi
if [[ -z "$codename" ]] && command -v lsb_release >/dev/null 2>&1; then
    codename=$(lsb_release -sc 2>/dev/null || true)
fi
if [[ -z "$codename" ]]; then
    printf '%s\n' 'ERROR: distribution codename could not be determined.'
    exit 1
fi
security_release="${codename}-security"

printf '%s\n' 'Fetching security update list...'
printf 'Source: %s\n\n' "$security_release"
if ! apt-get update >/dev/null; then
    printf '%s\n' 'ERROR: failed to refresh APT metadata.'
    exit 1
fi

simulation=$(apt-get -s -t "$security_release" --only-upgrade upgrade 2>&1)
simulation_rc=$?
if [[ "$simulation_rc" -ne 0 ]]; then
    printf '%s\n' "$simulation"
    printf '%s\n' 'ERROR: could not determine security updates.'
    exit 1
fi

updates=$(printf '%s\n' "$simulation" | awk '/^Inst /')
update_count=$(printf '%s\n' "$updates" | awk 'NF {n++} END {print n+0}')
printf 'Available security updates: %s packages\n' "$update_count"
if [[ "$update_count" -gt 0 ]]; then
    printf '%s\n' "$updates" | awk '{old=$3; new=$4; gsub(/[\[\]]/, "", old); gsub(/[()]/, "", new); printf "  %s (%s -> %s)\n", $2, old, new}'
fi

printf '\n%s\n' 'Applying security updates...'
if [[ "$update_count" -gt 0 ]]; then
    if ! apt-get -y -t "$security_release" --only-upgrade upgrade >/dev/null; then
        printf '%s\n' 'ERROR: security updates failed.'
        exit 1
    fi
fi
printf '  %s packages upgraded.\n' "$update_count"

printf '\n%s\n' 'Verification:'
if command -v dpkg-query >/dev/null 2>&1; then
    apache_version=$(dpkg-query -W -f='${Version}' apache2 2>/dev/null || true)
    [[ -n "$apache_version" ]] && printf '  apache2: %s (CURRENT)\n' "$apache_version"
fi

pending=$(apt-get -s -t "$security_release" --only-upgrade upgrade 2>/dev/null |
    awk '/^Inst / {n++} END {print n+0}')
printf '  Pending security updates: %s\n' "$pending"

if [[ "$pending" -eq 0 ]]; then
    printf '\n%s\n' 'Security updates applied successfully.'
    exit 0
fi

printf '\n%s\n' 'Security updates remain pending.'
exit 1
