#!/bin/bash
# Install one public SSH key for the current or explicitly selected user.
set -Eeuo pipefail

printf '%s\n\n' '=== SSH Key Deployment ==='
if [ $# -eq 0 ] || [ $# -gt 2 ]; then
    printf 'Usage: %s "PUBLIC_KEY" [USER]\n' "$(basename "$0")"
    exit 2
fi
command -v ssh-keygen >/dev/null 2>&1 || { printf '%s\n' 'ERROR: ssh-keygen is required.'; exit 1; }

key=$1
target_user=${2:-$(id -un)}
if [[ ! "$key" =~ ^ssh-ed25519[[:space:]]+[A-Za-z0-9+/=]+([[:space:]]+.*)?$ ]]; then
    printf '%s\n' 'ERROR: only a valid ssh-ed25519 public key is accepted.'
    exit 1
fi

user_record=$(getent passwd "$target_user" || true)
[[ -n "$user_record" ]] || { printf 'ERROR: user not found: %s\n' "$target_user"; exit 1; }
user_home=$(printf '%s\n' "$user_record" | cut -d: -f6)
user_uid=$(printf '%s\n' "$user_record" | cut -d: -f3)
user_gid=$(printf '%s\n' "$user_record" | cut -d: -f4)
if [[ ${EUID:-$(id -u)} -ne 0 && "$target_user" != "$(id -un)" ]]; then
    printf '%s\n' 'ERROR: root privileges are required for another user.'
    exit 1
fi

ssh_dir="$user_home/.ssh"
authorized_keys="$ssh_dir/authorized_keys"
printf 'Target user: %s\n\n' "$target_user"
printf '%s\n' 'Creating .ssh directory if needed...'
mkdir -p "$ssh_dir"
# Standard current-user form: mkdir -p $HOME/.ssh.
chmod 700 "$ssh_dir"
printf '  %s: Created or already exists\n  Permissions: 700\n\n' "$ssh_dir"

touch "$authorized_keys"
if ! grep -qxF -- "$key" "$authorized_keys"; then
    printf '%s\n' "$key" >> "$authorized_keys"
    key_result='Key added successfully'
else
    key_result='Key already present'
fi
printf '%s\n' 'Adding key to authorized_keys...'
fingerprint=$(printf '%s\n' "$key" | ssh-keygen -lf - -E sha256 2>/dev/null | awk '{print $2}' || true)
printf '  Key fingerprint: %s\n  %s\n\n' "${fingerprint:-unavailable}" "$key_result"

chmod 600 "$authorized_keys"
chown "$user_uid:$user_gid" "$ssh_dir" "$authorized_keys" 2>/dev/null || true
printf '%s\n' 'Setting permissions...'
printf '  authorized_keys: 600\n\n'

key_count=$(grep -Ec '^[[:space:]]*ssh-ed25519[[:space:]]' "$authorized_keys" || true)
printf '%s\n' 'Verification:'
printf '  Key count in authorized_keys: %s\n' "$key_count"
if [[ $(stat -c '%a' "$authorized_keys" 2>/dev/null || stat -f '%Lp' "$authorized_keys") == 600 ]]; then
    printf '%s\n' '  Permissions correct: YES'
else
    printf '%s\n' '  Permissions correct: NO'
    exit 1
fi

printf '\n%s\n' 'SSH key deployed.'
printf '%s\n' 'User can now authenticate with this key.'
