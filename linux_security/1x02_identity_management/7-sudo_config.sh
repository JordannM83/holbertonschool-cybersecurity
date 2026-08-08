#!/bin/bash
USERNAME="$1"
FILE="/etc/sudoers.d/junior"
echo "$USERNAME ALL=(ALL) /usr/bin/systemctl restart apache2, /usr/bin/journalctl" > "$FILE"
chmod 0440 "$FILE"
visudo -c -f "$FILE"
