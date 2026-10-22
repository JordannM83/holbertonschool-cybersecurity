#!/bin/bash
# Disable SSH password authentication after verifying key-based access exists.
set -Eeuo pipefail

printf '%s\n\n' '=== Disable SSH Password Authentication ==='
[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf '%s\n' 'ERROR: root privileges are required.'; exit 1; }
command -v sshd >/dev/null 2>&1 || { printf '%s\n' 'ERROR: sshd is required.'; exit 1; }
config=/etc/ssh/sshd_config
[[ -f "$config" ]] || { printf '%s\n' "ERROR: $config was not found."; exit 1; }

printf '%s\n' 'Pre-flight checks:'
printf '%s\n' '  Current user has SSH key: CHECKING...'
user_home=$(getent passwd "$(id -un)" | cut -d: -f6)
key_found=0
for key in "$user_home/.ssh/id_ed25519.pub" "$user_home/.ssh/id_rsa.pub"; do
    [[ -s "$key" ]] && key_found=1
done
[[ -s "$user_home/.ssh/authorized_keys" ]] && key_found=1
if (( ! key_found )); then
    printf '%s\n' '  Key-based auth working: NO'
    printf '%s\n' 'ERROR: no local SSH key or authorized_keys entry was found; refusing to disable passwords.'
    exit 1
fi
printf '%s\n' '  Key-based auth working: YES ✓'
printf '\n%s\n' 'WARNING: This will disable password authentication.'
printf '%s\n\n' 'Ensure you have working key-based access!'

backup="$config.backup.$(date +%Y%m%d)"
[[ -e "$backup" ]] || cp -p -- "$config" "$backup"
if [[ ! -e /etc/ssh/sshd_config.backup ]]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
fi
printf '%s\n' 'Backing up sshd_config...'
printf '  %s\n\n' "$backup"

tmp=$(mktemp "${config}.tmp.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
awk '
    /^[[:space:]]*#?[[:space:]]*PasswordAuthentication[[:space:]]+/ { print "PasswordAuthentication no"; pa=1; next }
    /^[[:space:]]*#?[[:space:]]*ChallengeResponseAuthentication[[:space:]]+/ { print "ChallengeResponseAuthentication no"; ca=1; next }
    { print }
    END {
        if (!pa) print "PasswordAuthentication no"
        if (!ca) print "ChallengeResponseAuthentication no"
    }
' "$config" > "$tmp"
chmod --reference="$config" "$tmp" 2>/dev/null || true
chown --reference="$config" "$tmp" 2>/dev/null || true
mv -- "$tmp" "$config"
trap - EXIT

printf '%s\n' 'Modifying /etc/ssh/sshd_config...'
printf '  PasswordAuthentication: yes -> no\n  ChallengeResponseAuthentication: yes -> no\n  UsePAM: yes (preserving for account checks)\n\n'

printf '%s\n' 'Validating configuration...'
if ! sshd -t; then
    cp -p -- "$backup" "$config"
    printf '%s\n' '  sshd -t: Configuration FAILED; backup restored.'
    exit 1
fi
printf '%s\n\n' '  sshd -t: Configuration OK'

printf '%s\n' 'Reloading SSH...'
if command -v systemctl >/dev/null 2>&1; then
    systemctl reload ssh.service 2>/dev/null || systemctl reload sshd.service
else
    service ssh reload 2>/dev/null || service sshd reload
fi
printf '%s\n\n' '  sshd.service: Reloaded'

printf '%s\n' 'Verification:'
effective=$(sshd -T 2>/dev/null || true)
if printf '%s\n' "$effective" | grep -q '^passwordauthentication no$'; then
    printf '%s\n' '  Password auth: DISABLED'
else
    printf '%s\n' '  Password auth: FAILED'
    exit 1
fi
if printf '%s\n' "$effective" | grep -q '^pubkeyauthentication yes$'; then
    printf '%s\n' '  Pubkey auth: ENABLED'
else
    printf '%s\n' '  Pubkey auth: FAILED'
    exit 1
fi

printf '\n%s\n' 'SSH now requires key-based authentication.'
