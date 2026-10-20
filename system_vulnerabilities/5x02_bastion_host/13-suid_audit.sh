#!/bin/bash
set -u

report=/var/log/hardening/suid_audit.txt
mkdir -p /var/log/hardening || { printf '%s\n' 'ERROR: could not create /var/log/hardening.'; exit 1; }
exec > >(tee "$report")
exec 2>&1

printf '%s\n\n' '=== SUID/SGID Binary Audit ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'WARNING: run as root for a complete filesystem inventory.'
fi

suid_list=$(mktemp)
sgid_list=$(mktemp)
trap 'rm -f -- "$suid_list" "$sgid_list"' EXIT
find / -xdev -type f -perm /4000 -print 2>/dev/null | sort > "$suid_list"
find / -xdev -type f -perm /2000 -print 2>/dev/null | sort > "$sgid_list"

unknown=0
classify() {
    local path=$1 kind=$2 owner group label base
    base=${path##*/}
    read -r owner group < <(stat -c '%U %G' "$path" 2>/dev/null || printf 'unknown unknown')
    case "$base" in
        sudo|passwd|chsh|ssh-agent) label='KNOWN SAFE' ;;
        newgrp|mount|umount|wall) label='REVIEW NEEDED' ;;
        *) label='UNKNOWN - HIGH RISK'; unknown=$((unknown + 1)) ;;
    esac
    printf '  %-32s %-8s %s\n' "$path" "$group" "$label"
}

printf '%s\n' 'SUID binaries (run as owner):'
suid_count=$(wc -l < "$suid_list")
if [[ "$suid_count" -gt 0 ]]; then
    while IFS= read -r path; do classify "$path" suid; done < "$suid_list"
else
    printf '  None found\n'
fi

printf '\n%s\n' 'SGID binaries (run as group):'
sgid_count=$(wc -l < "$sgid_list")
if [[ "$sgid_count" -gt 0 ]]; then
    while IFS= read -r path; do classify "$path" sgid; done < "$sgid_list"
else
    printf '  None found\n'
fi

printf '\n%s\n' 'Summary:'
printf '  Total SUID: %s\n' "$suid_count"
printf '  Total SGID: %s\n' "$sgid_count"
printf '  Unknown/Custom: %s (requires investigation)\n\n' "$unknown"
printf 'Full report saved to: %s\n' "$report"

