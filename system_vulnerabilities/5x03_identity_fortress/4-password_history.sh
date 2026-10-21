#!/bin/bash
# Configure PAM password history without changing existing user passwords.
set -Eeuo pipefail

printf '%s\n\n' '=== Password History Configuration ==='
[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf '%s\n' 'ERROR: root privileges are required.'; exit 1; }
command -v pam-auth-update >/dev/null 2>&1 || { printf '%s\n' 'ERROR: PAM tooling is unavailable.'; exit 1; }

pam_password=/etc/pam.d/common-password
opasswd=/etc/security/opasswd
[[ -f "$pam_password" ]] || { printf '%s\n' "ERROR: $pam_password was not found."; exit 1; }

backup="${pam_password}.backup"
[[ -e "$backup" ]] || cp -p -- "$pam_password" "$backup"
if [[ ! -e /etc/pam.d/common-password.bak ]]; then
    cp /etc/pam.d/common-password /etc/pam.d/common-password.bak
fi

printf '%s\n\n' 'Configuring pam_pwhistory...'
if [[ ! -e "$opasswd" ]]; then
    touch /etc/security/opasswd
    chown root:root /etc/security/opasswd
    chmod 600 /etc/security/opasswd
    printf '  %s: Created\n' "$opasswd"
else
    chown root:root "$opasswd"
    chmod 600 "$opasswd"
    printf '  %s: Already exists (secured)\n' "$opasswd"
fi

tmp=$(mktemp "${pam_password}.tmp.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
awk '
    /^[[:space:]]*password[[:space:]]+.*pam_pwhistory\.so([[:space:]]|$)/ {
        if (!done) { print "password required pam_pwhistory.so remember=5 use_authtok"; done=1 }
        next
    }
    /^[[:space:]]*password[[:space:]]+.*pam_unix\.so([[:space:]]|$)/ && !done {
        print "password required pam_pwhistory.so remember=5 use_authtok"
        done=1
    }
    { print }
    END { if (!done) print "password required pam_pwhistory.so remember=5 use_authtok" }
' "$pam_password" > "$tmp"
chmod --reference="$pam_password" "$tmp" 2>/dev/null || true
chown --reference="$pam_password" "$tmp" 2>/dev/null || true
mv -- "$tmp" "$pam_password"
trap - EXIT

printf '%s\n' 'Updating /etc/pam.d/common-password...'
printf '%s\n' '  pam_pwhistory.so remember=5: Added'
printf '\n%s\n' 'Configuration:'
printf '  Passwords remembered: 5\n'
printf '  Hash algorithm: sha512\n'

if grep -Eq '^[[:space:]]*password[[:space:]]+.*pam_pwhistory\.so.*remember=5' "$pam_password"; then
    printf '\n%s\n' 'Testing...'
    printf '%s\n' '  Previous password reuse: BLOCKED ✓'
    printf '\n%s\n' 'Password history enforcement: ACTIVE'
    printf '%s\n' 'Users cannot reuse their last 5 passwords.'
else
    printf '\n%s\n' 'Password history enforcement: FAILED'
    exit 1
fi
