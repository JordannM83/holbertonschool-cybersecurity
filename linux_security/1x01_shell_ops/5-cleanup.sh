#!/bin/bash
INPUT_FILE="$1"
while IFS= read -r username || [ -n "$Username"]; do
    if id "$username" &>/dev/null; then
        usermod -L "$username" &>/dev/null
        echo "User $username locked"
    else
        echo "User $username not found"
    fi
done < "$INPUT_FILE"