#!/bin/bash
set -u

printf '%s\n\n' '=== Network Tools Restriction ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: restricting network tools requires root privileges.'
    exit 1
fi

tools=(/usr/bin/nc /usr/bin/ncat /usr/bin/nmap /usr/sbin/tcpdump)
printf '%s\n' 'Restricting access (root only)...'
changed=0
failed=0
for tool in "${tools[@]}"; do
    if [[ -e "$tool" ]]; then
        old=$(stat -c '%a' "$tool" 2>/dev/null || printf 'unknown')
        if chmod 0750 -- "$tool" && chown root:root -- "$tool"; then
            printf '  %s: 0750 (was %s)\n' "$tool" "$old"
            changed=$((changed + 1))
        else
            printf '  %s: FAILED\n' "$tool"
            failed=1
        fi
    fi
done

printf '\n%s\n' 'Verification:'
for tool in "${tools[@]}"; do
    if [[ -e "$tool" ]]; then
        details=$(stat -c '%A %U %G' "$tool" 2>/dev/null || true)
        printf '  %s: %s\n' "${tool##*/}" "$details"
        [[ $(stat -c '%a' "$tool" 2>/dev/null || printf 0) == 750 ]] || failed=1
        [[ "$details" == *' root root' ]] || failed=1
    fi
done

if (( ! failed )); then
    printf '\n%s\n' 'Network tools restricted to root.'
    printf '%s\n' 'Regular users can no longer execute these binaries.'
    exit 0
fi
printf '\n%s\n' 'Network tool restriction incomplete.'
exit 1

