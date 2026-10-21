#!/bin/bash
# Read-only audit of PAM, password aging, and SSH authentication settings.
set -u

printf '%s\n\n' '=== PAM Configuration Audit ==='

show_module() {
    local file=$1 module=$2 description=$3
    if [[ -r "$file" ]] && grep -Eq "^[[:space:]]*[^#[:space:]]+[[:space:]]+$module([[:space:]]|$)" "$file"; then
        printf '  %s: %s\n' "$module" "$description"
    fi
}

printf '%s\n' '/etc/pam.d/common-auth:'
if [[ -r /etc/pam.d/common-auth ]]; then
    show_module /etc/pam.d/common-auth pam_unix.so 'Standard password authentication'
    show_module /etc/pam.d/common-auth pam_deny.so 'Fallback deny'
    show_module /etc/pam.d/common-auth pam_faillock.so 'Account lockout'
    show_module /etc/pam.d/common-auth pam_tally2.so 'Account lockout'
else
    printf '%s\n' '  NOT FOUND or unreadable'
fi

printf '\n%s\n' '/etc/pam.d/common-password:'
if [[ -r /etc/pam.d/common-password ]]; then
    show_module /etc/pam.d/common-password pam_unix.so 'Password change handling'
    if grep -Eq '^[[:space:]]*password[[:space:]].*(pam_pwquality|pam_cracklib)' /etc/pam.d/common-password; then
        printf '%s\n' '  Complexity enforcement: CONFIGURED'
    else
        printf '%s\n' '  Complexity enforcement: NONE'
    fi
    if grep -Eq '^[[:space:]]*password[[:space:]].*pam_unix\.so.*remember=' /etc/pam.d/common-password; then
        printf '%s\n' '  History enforcement: CONFIGURED'
    else
        printf '%s\n' '  History enforcement: NONE'
    fi
else
    printf '%s\n' '  NOT FOUND or unreadable'
fi

printf '\n%s\n' '/etc/pam.d/sshd:'
if [[ -r /etc/pam.d/sshd ]]; then
    grep -E '^[[:space:]]*@include[[:space:]]+|^[[:space:]]*auth[[:space:]]+.*pam_' /etc/pam.d/sshd \
        | sed -E 's/^[[:space:]]+//' | sed -E 's/[[:space:]]+#.*$//' \
        | while IFS= read -r line; do printf '  %s\n' "$line"; done
    if grep -Eq '^[[:space:]]*auth[[:space:]]+.*(pam_google_authenticator|pam_oath|pam_duo|pam_u2f|pam_sss)' /etc/pam.d/sshd; then
        printf '%s\n' '  MFA modules: CONFIGURED'
    else
        printf '%s\n' '  MFA modules: NONE'
    fi
else
    printf '%s\n' '  NOT FOUND or unreadable'
fi

printf '\n%s\n' 'Account Lockout:'
lockout=0
if grep -RqsE '^[[:space:]]*[^#].*pam_faillock\.so' /etc/pam.d 2>/dev/null; then
    printf '%s\n' '  pam_faillock: CONFIGURED'
    lockout=1
else
    printf '%s\n' '  pam_faillock: NOT CONFIGURED'
fi
if grep -RqsE '^[[:space:]]*[^#].*pam_tally2\.so' /etc/pam.d 2>/dev/null; then
    printf '%s\n' '  pam_tally2: CONFIGURED'
    lockout=1
else
    printf '%s\n' '  pam_tally2: NOT CONFIGURED'
fi

printf '\n%s\n' 'Password Aging:'
login_defs=/etc/login.defs
max_days=$(awk '$1 == "PASS_MAX_DAYS" {print $2; exit}' "$login_defs" 2>/dev/null || true)
min_days=$(awk '$1 == "PASS_MIN_DAYS" {print $2; exit}' "$login_defs" 2>/dev/null || true)
warn_days=$(awk '$1 == "PASS_WARN_AGE" {print $2; exit}' "$login_defs" 2>/dev/null || true)
max_days=${max_days:-unknown}; min_days=${min_days:-unknown}; warn_days=${warn_days:-unknown}
printf '  Default max days: %s\n' "$max_days"
printf '  Default min days: %s\n' "$min_days"
printf '  Default warn days: %s\n' "$warn_days"

printf '\n%s\n' 'SSH Authentication:'
ssh_config=/etc/ssh/sshd_config
ssh_effective=''
if command -v sshd >/dev/null 2>&1; then
    ssh_effective=$(sshd -T 2>/dev/null || true)
fi
ssh_setting() {
    local key=$1 default=$2 value
    value=$(printf '%s\n' "$ssh_effective" | awk -v key="$key" '$1 == key {print $2; exit}')
    if [[ -z "$value" && -r "$ssh_config" ]]; then
        value=$(awk -v key="$key" 'tolower($1) == tolower(key) && $1 !~ /^#/ {print $2; exit}' "$ssh_config")
    fi
    printf '%s' "${value:-$default}"
}
password_auth=$(ssh_setting passwordauthentication unknown)
pubkey_auth=$(ssh_setting pubkeyauthentication unknown)
challenge_auth=$(ssh_setting challengeresponseauthentication unknown)
printf '  PasswordAuthentication: %s' "$password_auth"
[[ "$password_auth" == yes ]] && printf ' (INSECURE)'
printf '\n'
printf '  PubkeyAuthentication: %s\n' "$pubkey_auth"
printf '  ChallengeResponseAuthentication: %s\n' "$challenge_auth"

weak=0
[[ "$lockout" -eq 0 ]] && weak=1
[[ "$max_days" == 99999 || "$max_days" == 0 || "$max_days" == unknown ]] && weak=1
[[ "$password_auth" == yes || "$password_auth" == unknown ]] && weak=1
if ((weak)); then
    printf '\n%s\n' 'Summary: Identity controls are WEAK'
else
    printf '\n%s\n' 'Summary: Identity controls are CONFIGURED'
fi
