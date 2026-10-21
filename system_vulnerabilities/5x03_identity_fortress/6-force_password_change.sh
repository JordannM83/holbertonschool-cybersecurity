#!/bin/bash
# Force selected accounts to change their passwords at next login.
set -Eeuo pipefail

printf '%s\n\n' '=== Force Password Change ==='
[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf '%s\n' 'ERROR: root privileges are required.'; exit 1; }
if [[ $# -eq 0 ]]; then
    printf 'Usage: %s USER [USER ...]\n' "$(basename "$0")"
    exit 2
fi
command -v chage >/dev/null 2>&1 || { printf '%s\n' 'ERROR: chage is required.'; exit 1; }

printf '%s\n\n' 'Processing users with compromised passwords...'
changed=0
for user in "$@"; do
    if ! getent passwd "$user" >/dev/null 2>&1; then
        printf '%s\n' "$user: account not found"
        exit 1
    fi
    printf '%s\n' "$user:"
    if chage -d 0 "$user"; then
        printf '%s\n' '  Password expired: FORCED'
        printf '%s\n\n' '  Must change at next login: YES'
        changed=$((changed + 1))
    else
        printf '%s\n' '  Password expiry: FAILED'
        exit 1
    fi
done

printf '%s\n' 'Verification:'
for user in "$@"; do
    printf '  chage -l %s | grep "Password expires"\n' "$user"
    expiry=$(chage -l "$user" | grep 'Password expires' || true)
    printf '  %s\n' "$expiry"
done

printf '\n%d users must change password at next login.\n' "$changed"
