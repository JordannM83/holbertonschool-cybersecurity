#!/usr/bin/bash
if ! dpkg -s "$1" >/dev/null 2>&1; then
    apt-get update
    apt-get install -y "$1"
fi
PAM_FILE="$2"
sed -i '/pam_pwquality\.so/d' "$PAM_FILE"
sed -i '/pam_unix\.so/i password requisite pam_pwquality.so retry=3 minlen=12 minclass=3' "$PAM_FILE"
