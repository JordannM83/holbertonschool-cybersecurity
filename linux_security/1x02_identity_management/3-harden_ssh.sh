#!/bin/bash

CONFIG="$1"

if [ -z "$CONFIG" ] || [ ! -f "$CONFIG" ]; then
    exit 1
fi

if grep -Eq '^[[:space:]]*#?[[:space:]]*PermitRootLogin' "$CONFIG"; then
    sed -i -E 's|^[[:space:]]*#?[[:space:]]*PermitRootLogin.*|PermitRootLogin no|' "$CONFIG"
else
    echo "PermitRootLogin no" >> "$CONFIG"
fi

if grep -Eq '^[[:space:]]*#?[[:space:]]*PasswordAuthentication' "$CONFIG"; then
    sed -i -E 's|^[[:space:]]*#?[[:space:]]*PasswordAuthentication.*|PasswordAuthentication no|' "$CONFIG"
else
    echo "PasswordAuthentication no" >> "$CONFIG"
fi

if grep -Eq '^[[:space:]]*#?[[:space:]]*PubkeyAuthentication' "$CONFIG"; then
    sed -i -E 's|^[[:space:]]*#?[[:space:]]*PubkeyAuthentication.*|PubkeyAuthentication yes|' "$CONFIG"
else
    echo "PubkeyAuthentication yes" >> "$CONFIG"
fi

if sshd -t -f "$CONFIG"; then
    service ssh reload
fi
