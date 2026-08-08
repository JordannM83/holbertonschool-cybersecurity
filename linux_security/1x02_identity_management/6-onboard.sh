#!/bin/bash
USERNAME="$1"
useradd -m -s /bin/bash "$USERNAME"
passwd -l $1
USER_HOME="/home/$USERNAME"
SSH_DIR="$USER_HOME/.ssh"
AUTH_KEYS="$$USER_HOME/.ssh/authorized_keys"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
echo "$2" >> "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"
chown -R "$USERNAME:$USERNAME" "$SSH_DIR"
