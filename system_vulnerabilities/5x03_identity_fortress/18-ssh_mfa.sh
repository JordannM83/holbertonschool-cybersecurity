#!/bin/bash
# Require an SSH public key and Google Authenticator TOTP for SSH login.
set -Eeuo pipefail

printf '%s\n\n' '=== SSH Multi-Factor Authentication ==='
[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf '%s\n' 'ERROR: root privileges are required.'; exit 1; }
command -v sshd >/dev/null 2>&1 || { printf '%s\n' 'ERROR: sshd is required.'; exit 1; }

pam_config=/etc/pam.d/sshd
ssh_config=/etc/ssh/sshd_config
[[ -f "$pam_config" && -f "$ssh_config" ]] || { printf '%s\n' 'ERROR: SSH/PAM configuration is incomplete.'; exit 1; }

printf '%s\n' 'Backing up configurations...'
[[ -e /etc/pam.d/sshd.backup ]] || cp /etc/pam.d/sshd /etc/pam.d/sshd.backup
[[ -e /etc/ssh/sshd_config.backup ]] || cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
printf '%s\n' '  /etc/pam.d/sshd.backup'
printf '%s\n\n' '  /etc/ssh/sshd_config.backup'

printf '%s\n' 'Configuring /etc/pam.d/sshd...'
if ! grep -Eq '^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_google_authenticator\.so' "$pam_config"; then
    tmp=$(mktemp "${pam_config}.tmp.XXXXXX")
    trap 'rm -f -- "$tmp"' EXIT
    awk '
        /^[[:space:]]*auth[[:space:]]+include[[:space:]]+common-auth/ && !done {
            print "auth required pam_google_authenticator.so"
            done=1
        }
        { print }
        END { if (!done) print "auth required pam_google_authenticator.so" }
    ' "$pam_config" > "$tmp"
    chmod --reference="$pam_config" "$tmp" 2>/dev/null || true
    chown --reference="$pam_config" "$tmp" 2>/dev/null || true
    mv -- "$tmp" "$pam_config"
    trap - EXIT
fi
printf '%s\n' '  Adding: auth required pam_google_authenticator.so'

printf '\n%s\n' 'Configuring /etc/ssh/sshd_config...'
tmp=$(mktemp "${ssh_config}.tmp.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
awk '
    /^[[:space:]]*#?[[:space:]]*ChallengeResponseAuthentication[[:space:]]+/ { print "ChallengeResponseAuthentication yes"; challenge=1; next }
    /^[[:space:]]*#?[[:space:]]*KbdInteractiveAuthentication[[:space:]]+/ { print "KbdInteractiveAuthentication yes"; kbd=1; next }
    /^[[:space:]]*#?[[:space:]]*AuthenticationMethods[[:space:]]+/ { print "AuthenticationMethods publickey,keyboard-interactive"; methods=1; next }
    { print }
    END {
        if (!challenge) print "ChallengeResponseAuthentication yes"
        if (!kbd) print "KbdInteractiveAuthentication yes"
        if (!methods) print "AuthenticationMethods publickey,keyboard-interactive"
    }
' "$ssh_config" > "$tmp"
chmod --reference="$ssh_config" "$tmp" 2>/dev/null || true
chown --reference="$ssh_config" "$tmp" 2>/dev/null || true
mv -- "$tmp" "$ssh_config"
trap - EXIT
printf '  ChallengeResponseAuthentication: no -> yes\n  AuthenticationMethods: publickey,keyboard-interactive\n\n'

printf '%s\n' 'Validating configuration...'
if ! sshd -t; then
    cp -p -- /etc/pam.d/sshd.backup "$pam_config"
    cp -p -- /etc/ssh/sshd_config.backup "$ssh_config"
    printf '%s\n' '  sshd -t: FAILED; configurations restored.'
    exit 1
fi
if ! grep -Eq '^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_google_authenticator\.so' "$pam_config"; then
    printf '%s\n' '  PAM syntax: FAILED'
    exit 1
fi
printf '%s\n' '  sshd -t: OK'
printf '%s\n\n' '  PAM syntax: OK'

printf '%s\n' 'Reloading SSH...'
if command -v systemctl >/dev/null 2>&1; then
    systemctl reload ssh.service 2>/dev/null || systemctl reload sshd.service
else
    service ssh reload 2>/dev/null || service sshd reload
fi
printf '%s\n\n' '  sshd.service: Reloaded'

printf '%s\n' 'SSH MFA Configuration:'
printf '  First factor: SSH Public Key\n  Second factor: TOTP Code (Google Authenticator)\n\n'
printf '%s\n' 'Users must now provide BOTH key AND TOTP code to log in.'
