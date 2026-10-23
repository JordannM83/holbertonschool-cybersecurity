#!/bin/bash
# Enroll the current user in Google Authenticator using secure defaults.
set -Eeuo pipefail

printf '%s\n\n' '=== TOTP Setup for Current User ==='
command -v google-authenticator >/dev/null 2>&1 || {
    printf '%s\n' 'ERROR: google-authenticator is not installed.'
    exit 1
}

secret_file=${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}/.google_authenticator
if [[ -e "$secret_file" ]]; then
    printf 'ERROR: %s already exists; refusing to overwrite an existing TOTP secret.\n' "$secret_file"
    exit 1
fi

umask 077
printf '%s\n\n' 'Running google-authenticator with secure defaults...'
printf '%s\n' 'Follow the prompts to confirm the secret, QR code, and emergency scratch codes.'
if ! google-authenticator -t -d -r 3 -R 30 -w 3; then
    printf '%s\n' 'ERROR: TOTP enrollment failed or was cancelled.'
    exit 1
fi

[[ -f "$secret_file" ]] || { printf 'ERROR: %s was not created.\n' "$secret_file"; exit 1; }
chmod 600 "$secret_file"

printf '\n%s\n' "Configuration saved to $secret_file"
printf '%s\n' 'Settings applied:'
printf '  Time-based tokens: YES\n  Rate limiting: 3 logins per 30 seconds\n  Token reuse: DISALLOWED\n  Window size: 3 (allows clock skew)\n\n'
printf '%s\n' 'IMPORTANT: Save your emergency codes securely!'
printf '%s\n' 'Scan the QR code with your authenticator app.'
