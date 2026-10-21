#!/bin/bash
# Configure strong password policy through libpam-pwquality.
# Package-repair recovery is handled by the lifecycle script with
# `dpkg --configure -a` (or `dpkg --configure --pending`) before PAM changes.
# Its dependency repair step uses `apt-get install -f` when required.
set -Eeuo pipefail

printf '%s\n\n' '=== Password Complexity Configuration ==='
[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf '%s\n' 'ERROR: root privileges are required.'; exit 1; }
command -v apt-get >/dev/null 2>&1 || { printf '%s\n' 'ERROR: apt-get is required.'; exit 1; }

package=libpam-pwquality
printf '%s\n' 'Installing libpam-pwquality...'
if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii '; then
    printf '%s\n' '  Already installed: libpam-pwquality'
else
    apt-get update >/dev/null
    apt-get install -y "$package" >/dev/null
    printf '%s\n' '  Installed: libpam-pwquality'
fi

pwquality=/etc/security/pwquality.conf
pam_password=/etc/pam.d/common-password
[[ -f "$pwquality" && -f "$pam_password" ]] || { printf '%s\n' 'ERROR: required PAM configuration files are missing.'; exit 1; }

backup_once() {
    local file=$1 backup="${file}.backup"
    [[ -e "$backup" ]] || cp -p -- "$file" "$backup"
    printf '  %s created\n' "$backup"
}

printf '\n%s\n' 'Backing up configuration...'
backup_once "$pwquality"
backup_once "$pam_password"

set_option() {
    local key=$1 value=$2
    sed -i -E "/^[[:space:]]*#?[[:space:]]*${key}[[:space:]]*=/d" "$pwquality"
    printf '%s = %s\n' "$key" "$value" >> "$pwquality"
}

printf '\n%s\n' 'Configuring /etc/security/pwquality.conf:'
set_option minlen 12
set_option dcredit -1
set_option ucredit -1
set_option lcredit -1
set_option ocredit -1
set_option usercheck 1
set_option difok 3
printf '  minlen = 12\n  dcredit = -1 (require digit)\n  ucredit = -1 (require uppercase)\n  lcredit = -1 (require lowercase)\n  ocredit = -1 (require special)\n  usercheck = 1 (reject username in password)\n  difok = 3 (must differ from old password)\n'

tmp=$(mktemp "${pam_password}.tmp.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
awk '
    /^[[:space:]]*password[[:space:]]+.*pam_pwquality\.so([[:space:]]|$)/ {
        if (!done) { print "password requisite pam_pwquality.so retry=3"; done=1 }
        next
    }
    /^[[:space:]]*password[[:space:]]+.*pam_unix\.so([[:space:]]|$)/ && !done {
        print "password requisite pam_pwquality.so retry=3"
        done=1
    }
    { print }
    END {
        if (!done) print "password requisite pam_pwquality.so retry=3"
    }
' "$pam_password" > "$tmp"
chmod --reference="$pam_password" "$tmp" 2>/dev/null || true
chown --reference="$pam_password" "$tmp" 2>/dev/null || true
mv -- "$tmp" "$pam_password"
trap - EXIT

printf '\n%s\n' 'Updating /etc/pam.d/common-password...'
printf '%s\n' '  pam_pwquality.so: Configured'

printf '\n%s\n' 'Testing enforcement...'
if command -v pwscore >/dev/null 2>&1; then
    if printf '%s\n' weak | pwscore >/dev/null 2>&1; then
        printf '%s\n' '  Attempt "weak": ACCEPTED (review pwquality configuration)'
    else
        printf '%s\n' '  Attempt "weak": REJECTED ✓'
    fi
    if printf '%s\n' Password123 | pwscore >/dev/null 2>&1; then
        printf '%s\n' '  Attempt "Password123": ACCEPTED (review pwquality configuration)'
    else
        printf '%s\n' '  Attempt "Password123": REJECTED ✓'
    fi
else
    printf '%s\n' '  pwscore unavailable; configuration and PAM stack verified'
fi

if grep -Eq '^[[:space:]]*password[[:space:]]+.*pam_pwquality\.so' "$pam_password" && \
   grep -Eq '^[[:space:]]*minlen[[:space:]]*=[[:space:]]*12' "$pwquality"; then
    printf '\n%s\n' 'Password complexity enforcement: ACTIVE'
else
    printf '\n%s\n' 'Password complexity enforcement: FAILED'
    exit 1
fi
