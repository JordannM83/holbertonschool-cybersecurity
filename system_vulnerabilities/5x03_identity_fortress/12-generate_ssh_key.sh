#!/bin/bash
# Generate a non-destructive ED25519 SSH key pair for the current user.
set -Eeuo pipefail

printf '%s\n\n' '=== SSH Key Generation ==='
command -v ssh-keygen >/dev/null 2>&1 || { printf '%s\n' 'ERROR: ssh-keygen is required.'; exit 1; }

ssh_dir=${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}
ssh_dir="$ssh_dir/.ssh"
private_key="$ssh_dir/id_ed25519"
public_key="${private_key}.pub"
# Equivalent standard path: ssh-keygen -t ed25519 -f $HOME/.ssh/id_ed25519.

umask 077
mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"
if [[ -e "$private_key" || -e "$public_key" ]]; then
    printf 'ERROR: %s already exists; refusing to overwrite an existing key.\n' "$private_key"
    exit 1
fi

printf '%s\n' 'Generating ED25519 key pair...'
printf '  Algorithm: ED25519 (recommended)\n  Key file: %s\n\n' "$private_key"
printf '%s\n' 'Enter passphrase (recommended):'
printf '%s\n' 'Enter same passphrase again:'
if ! ssh-keygen -t ed25519 -f "$private_key" -C "$(id -un)@$(hostname -s 2>/dev/null || hostname)"; then
    printf '%s\n' 'ERROR: SSH key generation failed.'
    exit 1
fi

chmod 600 "$private_key"
chmod 644 "$public_key"
printf '\n%s\n' 'Key pair generated:'
printf '  Private key: %s\n  Public key: %s\n\n' "$private_key" "$public_key"
printf '%s\n' 'Setting permissions...'
printf '  Private key: 600 (owner read/write only)\n  Public key: 644\n\n'

printf '%s\n' 'Public key fingerprint:'
ssh-keygen -lf "$public_key" -E sha256 | sed 's/^/  /'
printf '\n%s\n' 'Your public key:'
cat "$public_key"
printf '\n%s\n' "Next step: Add this public key to target servers' authorized_keys"
