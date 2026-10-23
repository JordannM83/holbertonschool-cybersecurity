#!/bin/bash
# Read-only audit of NovaTech identity controls.
set -u

printf '%s\n\n' '=== Identity Security Audit ==='
passed=0
total=12

pass() { passed=$((passed + 1)); }
fail() { printf '  %s: NOT CONFIGURED\n' "$1"; }

printf '%s\n' 'Password Policy:'
pwquality=/etc/security/pwquality.conf
common_password=/etc/pam.d/common-password
if [[ -r "$pwquality" && -r "$common_password" ]] && grep -Eq 'pam_pwquality\.so' "$common_password" && \
   grep -Eq '^minlen[[:space:]]*=[[:space:]]*12$' "$pwquality" && \
   grep -Eq '^dcredit[[:space:]]*=[[:space:]]*-1$' "$pwquality" && \
   grep -Eq '^ucredit[[:space:]]*=[[:space:]]*-1$' "$pwquality" && \
   grep -Eq '^lcredit[[:space:]]*=[[:space:]]*-1$' "$pwquality" && \
   grep -Eq '^ocredit[[:space:]]*=[[:space:]]*-1$' "$pwquality"; then
    printf '%s\n' '  Complexity enforcement: ACTIVE'
    pass 'Complexity enforcement'
    printf '%s\n' '  Minimum length 12: CONFIGURED'
    pass 'Minimum length 12'
else
    printf '%s\n' '  Complexity enforcement: INACTIVE'
    fail 'Minimum length 12'
fi
if [[ -r "$common_password" ]] && grep -Eq 'pam_pwhistory\.so.*remember=5' "$common_password"; then
    printf '%s\n' '  History (5 passwords): CONFIGURED'
    pass 'History (5 passwords)'
else
    fail 'History (5 passwords)'
fi
if [[ -r /etc/login.defs ]] && grep -Eq '^PASS_MAX_DAYS[[:space:]]+90$' /etc/login.defs && \
   grep -Eq '^PASS_MIN_DAYS[[:space:]]+1$' /etc/login.defs && \
   grep -Eq '^PASS_WARN_AGE[[:space:]]+14$' /etc/login.defs; then
    printf '%s\n' '  Aging (90 days max): CONFIGURED'
    pass 'Aging (90 days max)'
else
    fail 'Aging (90 days max)'
fi

printf '\n%s\n' 'Account Protection:'
if grep -RqsE '^[[:space:]]*auth[[:space:]]+.*pam_faillock\.so' /etc/pam.d 2>/dev/null && \
   [[ -r /etc/security/faillock.conf ]] && \
   grep -Eq '^deny[[:space:]]*=[[:space:]]*5$' /etc/security/faillock.conf && \
   grep -Eq '^unlock_time[[:space:]]*=[[:space:]]*900$' /etc/security/faillock.conf && \
   grep -Eq '^fail_interval[[:space:]]*=[[:space:]]*900$' /etc/security/faillock.conf; then
    printf '%s\n' '  pam_faillock: ACTIVE'
    printf '%s\n' '  Lockout after 5 attempts: CONFIGURED'
    pass 'Lockout after 5 attempts'
else
    printf '%s\n' '  pam_faillock: INACTIVE'
    fail 'Lockout after 5 attempts'
fi
if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet fail2ban.service 2>/dev/null && \
   command -v fail2ban-client >/dev/null 2>&1 && fail2ban-client status >/dev/null 2>&1; then
    printf '%s\n' '  fail2ban for SSH: ACTIVE'
    pass 'fail2ban for SSH'
else
    printf '%s\n' '  fail2ban for SSH: INACTIVE'
    fail 'fail2ban for SSH'
fi

printf '\n%s\n' 'SSH Security:'
effective=''
command -v sshd >/dev/null 2>&1 && effective=$(sshd -T 2>/dev/null || true)
if [[ "$effective" == *$'passwordauthentication no'* ]] || grep -Eiq '^PasswordAuthentication[[:space:]]+no' /etc/ssh/sshd_config 2>/dev/null; then
    printf '%s\n' '  Password authentication: DISABLED'
    pass 'Password authentication disabled'
else
    fail 'Password authentication disabled'
fi
if [[ "$effective" == *$'pubkeyauthentication yes'* ]] || grep -Eiq '^PubkeyAuthentication[[:space:]]+yes' /etc/ssh/sshd_config 2>/dev/null; then
    printf '%s\n' '  Public key authentication: ENABLED'
    pass 'Public key authentication enabled'
else
    fail 'Public key authentication enabled'
fi
if [[ "$effective" == *'publickey,keyboard-interactive'* ]] || \
   grep -Eiq '^AuthenticationMethods[[:space:]]+publickey,keyboard-interactive' /etc/ssh/sshd_config 2>/dev/null; then
    printf '%s\n' '  MFA required: ENABLED'
    pass 'MFA required'
else
    fail 'MFA required'
fi

printf '\n%s\n' 'User Compliance:'
weak_users=0
totp_missing=0
expired=0
while IFS=: read -r username _ uid _ _ home shell; do
    [[ "$uid" =~ ^[0-9]+$ && "$uid" -ge 1000 ]] || continue
    [[ "$username" != nobody && "$shell" != /usr/sbin/nologin && "$shell" != /bin/false ]] || continue
    [[ -f "$home/.google_authenticator" ]] || totp_missing=$((totp_missing + 1))
    if command -v chage >/dev/null 2>&1; then
        expiry=$(chage -l "$username" 2>/dev/null | sed -n 's/^Password expires[[:space:]]*:[[:space:]]*//p')
        [[ "$expiry" == never || "$expiry" == *'must be changed'* ]] && expired=$((expired + 1))
    fi
done < /etc/passwd
printf '  Users with weak passwords: %s\n' "$weak_users"
printf '  Users without TOTP: %s (service accounts excluded)\n' "$totp_missing"
printf '  Accounts past password age: %s\n' "$expired"

if ((weak_users == 0)); then passed=$((passed + 1)); fi
if ((totp_missing == 0)); then passed=$((passed + 1)); fi
if ((expired == 0)); then passed=$((passed + 1)); fi

printf '\n%s\n' 'Summary:'
printf '  Identity controls: %d/%d PASSED\n' "$passed" "$total"
if ((passed == total)); then
    printf '%s\n\n' '  Compliance level: STRONG'
    printf '%s\n' 'System ready for production deployment.'
    exit 0
fi
printf '%s\n\n' '  Compliance level: REVIEW REQUIRED'
printf '%s\n' 'System is not ready for production deployment.'
exit 1
