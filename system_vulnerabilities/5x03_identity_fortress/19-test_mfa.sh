#!/bin/bash
# Verify MFA requirements without attempting to lock out the current user.
set -u

printf '%s\n\n' '=== MFA Testing ==='
pam_config=/etc/pam.d/sshd
ssh_config=/etc/ssh/sshd_config
user_home=${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}
totp_file="$user_home/.google_authenticator"
failures=0

printf '%s\n\n' 'Testing authentication requirements...'
printf '%s\n' 'Test 1: SSH with key only (no TOTP)'
# Safe operator-run check: ssh -i "$HOME/.ssh/id_ed25519" user@host.
printf '%s\n' '  Expected: Prompt for verification code'
printf '%s\n' '  Result: NOT TESTED LIVE (configuration checked below)'

printf '\n%s\n' 'Test 2: SSH with TOTP only (no key)'
printf '%s\n' '  Expected: Connection refused'
printf '%s\n' '  Result: NOT TESTED LIVE (configuration checked below)'

printf '\n%s\n' 'Test 3: PAM configuration check'
if [[ -r "$pam_config" ]] && grep -Eq '^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_google_authenticator\.so' "$pam_config"; then
    printf '%s\n' '  pam_google_authenticator.so: Present in /etc/pam.d/sshd ✓'
else
    printf '%s\n' '  pam_google_authenticator.so: Missing from /etc/pam.d/sshd'
    failures=$((failures + 1))
fi

printf '\n%s\n' 'Test 4: SSH configuration check'
effective=''
if command -v sshd >/dev/null 2>&1; then
    effective=$(sshd -T 2>/dev/null || true)
fi
methods=$(printf '%s\n' "$effective" | awk '$1 == "authenticationmethods" {$1=""; sub(/^ /, ""); print; exit}')
if [[ "$methods" == *publickey,keyboard-interactive* ]] || grep -Eiq '^[[:space:]]*AuthenticationMethods[[:space:]]+publickey,keyboard-interactive' "$ssh_config" 2>/dev/null; then
    printf '%s\n' '  AuthenticationMethods: publickey,keyboard-interactive ✓'
else
    printf '%s\n' '  AuthenticationMethods: NOT CONFIGURED'
    failures=$((failures + 1))
fi
if [[ "$effective" == *$'challengeresponseauthentication yes'* ]] || grep -Eiq '^[[:space:]]*ChallengeResponseAuthentication[[:space:]]+yes' "$ssh_config" 2>/dev/null; then
    printf '%s\n' '  ChallengeResponseAuthentication: yes ✓'
else
    printf '%s\n' '  ChallengeResponseAuthentication: NOT ENABLED'
    failures=$((failures + 1))
fi

printf '\n%s\n' 'Test 5: User TOTP configuration'
if [[ -f "$totp_file" ]]; then
    printf '  %s: Exists ✓\n' "$totp_file"
else
    printf '  %s: Missing\n' "$totp_file"
    failures=$((failures + 1))
fi
mode=$(stat -c '%a' "$totp_file" 2>/dev/null || true)
if [[ "$mode" == 600 ]]; then
    printf '%s\n' '  Permissions (600): Correct ✓'
else
    printf '  Permissions (600): Incorrect (%s)\n' "${mode:-unknown}"
    failures=$((failures + 1))
fi

if ((failures == 0)); then
    printf '\n%s\n' 'All MFA tests: PASSED'
    printf '%s\n' 'Two-factor authentication is properly configured.'
    exit 0
fi

printf '\n%s\n' "All MFA tests: FAILED ($failures check(s) failed)"
exit 1
