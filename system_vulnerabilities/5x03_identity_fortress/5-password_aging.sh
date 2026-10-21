#!/bin/bash
# Configure password-aging defaults and apply them to regular users.
set -Eeuo pipefail

printf '%s\n\n' '=== Password Aging Configuration ==='
[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf '%s\n' 'ERROR: root privileges are required.'; exit 1; }
login_defs=/etc/login.defs
[[ -f "$login_defs" ]] || { printf '%s\n' "ERROR: $login_defs was not found."; exit 1; }

backup=/etc/login.defs.backup
[[ -e "$backup" ]] || cp "$login_defs" "$backup"

get_value() {
    awk -v key="$1" '$1 == key {print $2; exit}' "$login_defs" 2>/dev/null || true
}

set_value() {
    local key=$1 value=$2
    if grep -Eq "^[[:space:]]*${key}[[:space:]]+" "$login_defs"; then
        sed -i -E "s|^[[:space:]]*${key}[[:space:]]+.*$|${key} ${value}|" "$login_defs"
    else
        printf '%s %s\n' "$key" "$value" >> "$login_defs"
    fi
}

printf '%s\n' 'Configuring /etc/login.defs...'
printf '  PASS_MAX_DAYS: %s -> 90\n' "$(get_value PASS_MAX_DAYS)"
printf '  PASS_MIN_DAYS: %s -> 1\n' "$(get_value PASS_MIN_DAYS)"
printf '  PASS_WARN_AGE: %s -> 14\n' "$(get_value PASS_WARN_AGE)"
set_value PASS_MAX_DAYS 90
set_value PASS_MIN_DAYS 1
set_value PASS_WARN_AGE 14

printf '\n%s\n' 'Note: These settings apply to NEW accounts only.'
printf '%s\n\n' 'Existing accounts must be updated with chage.'
printf '%s\n' 'Applying to existing users...'

# Equivalent per-user forms: chage -M 90 $user -m 1 -W 14; chage -m 1 $user;
# chage -W 14 $user.
users=0
while IFS=: read -r username _ uid _ _ home shell; do
    [[ "$uid" =~ ^[0-9]+$ && "$uid" -ge 1000 ]] || continue
    [[ "$username" != nobody && "$shell" != /usr/sbin/nologin && "$shell" != /bin/false ]] || continue
    if chage -M 90 -m 1 -W 14 "$username"; then
        printf '  %s: Max=90, Min=1, Warn=14\n' "$username"
        users=$((users + 1))
    else
        printf '  %s: FAILED\n' "$username"
        exit 1
    fi
done < /etc/passwd

printf '  [Skipping system accounts]\n'
if grep -Eq '^PASS_MAX_DAYS[[:space:]]+90$' "$login_defs" && \
   grep -Eq '^PASS_MIN_DAYS[[:space:]]+1$' "$login_defs" && \
   grep -Eq '^PASS_WARN_AGE[[:space:]]+14$' "$login_defs"; then
    printf '\n%s\n' 'Password aging: CONFIGURED'
else
    printf '\n%s\n' 'Password aging: FAILED'
    exit 1
fi
