#!/bin/sh
# Apply PAM, account, SSH, and root-access controls idempotently.
set -u

failures=0
log() {
    printf '%s\n' "$*"
}
fail() {
    log "ERROR: $*"
    failures=$((failures + 1))
}
backup_once() {
    source=$1
    backup="${source}.backup"
    if [ -f "$source" ] && [ ! -e "$backup" ]; then
        cp -p "$source" "$backup" || fail "could not back up $source"
    fi
}
ensure_line() {
    file=$1
    line=$2
    grep -Fqx -- "$line" "$file" 2>/dev/null || printf '%s\n' "$line" >> "$file"
}
set_sshd_option() {
    key=$1
    value=$2
    file=/etc/ssh/sshd_config
    tmp=$(mktemp)
    awk -v key="$key" -v value="$value" '
        tolower($1) == tolower(key) && $1 !~ /^#/ {
            if (!done) { print key " " value; done=1 }
            next
        }
        { print }
        END { if (!done) print key " " value }
    ' "$file" > "$tmp"
    if ! install -o root -g root -m 0644 "$tmp" "$file"; then
        fail "could not update $file"
    fi
    rm -f "$tmp"
}

if [ "$(id -u)" -ne 0 ]; then
    printf '%s\n' 'ERROR: init-identity.sh must run as root.' >&2
    exit 2
fi

log '=== Hardened Shield Identity Configuration ==='

if command -v dpkg-query >/dev/null 2>&1 && \
    ! dpkg-query -W -f='${db:Status-Abbrev}' libpam-pwquality 2>/dev/null | grep -q '^ii '; then
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update >/dev/null 2>&1 &&
            apt-get install -y --no-install-recommends libpam-pwquality >/dev/null 2>&1 ||
            fail 'could not install libpam-pwquality'
    else
        fail 'apt-get is required to install libpam-pwquality'
    fi
fi

PWQUALITY=/etc/security/pwquality.conf
COMMON_PASSWORD=/etc/pam.d/common-password
COMMON_AUTH=/etc/pam.d/common-auth
COMMON_ACCOUNT=/etc/pam.d/common-account
FAILLOCK=/etc/security/faillock.conf
LOGIN_DEFS=/etc/login.defs
SSHD=/etc/ssh/sshd_config

for file in "$PWQUALITY" "$COMMON_PASSWORD" "$COMMON_AUTH" "$COMMON_ACCOUNT" "$LOGIN_DEFS" "$SSHD"; do
    [ -f "$file" ] && backup_once "$file" || fail "missing configuration file: $file"
done

log 'Configuring password complexity and history...'
touch "$PWQUALITY"
for setting in 'minlen = 12' 'dcredit = -1' 'ucredit = -1' \
    'lcredit = -1' 'ocredit = -1' 'usercheck = 1' 'difok = 3'; do
    key=$(printf '%s\n' "$setting" | awk '{print $1}')
    sed -i -E "/^[[:space:]]*#?[[:space:]]*${key}[[:space:]]*=/d" "$PWQUALITY"
    printf '%s\n' "$setting" >> "$PWQUALITY"
done
chmod 0644 "$PWQUALITY"

touch "$COMMON_PASSWORD"
ensure_line "$COMMON_PASSWORD" 'password requisite pam_pwquality.so retry=3'
ensure_line "$COMMON_PASSWORD" 'password required pam_pwhistory.so remember=5 use_authtok'

log 'Configuring account lockout...'
touch "$FAILLOCK"
for setting in 'deny = 5' 'unlock_time = 900' 'fail_interval = 900'; do
    key=$(printf '%s\n' "$setting" | awk '{print $1}')
    sed -i -E "/^[[:space:]]*#?[[:space:]]*${key}[[:space:]]*=/d" "$FAILLOCK"
    printf '%s\n' "$setting" >> "$FAILLOCK"
done
chmod 0644 "$FAILLOCK"
ensure_line "$COMMON_AUTH" 'auth required pam_faillock.so preauth'
ensure_line "$COMMON_AUTH" 'auth [default=die] pam_faillock.so authfail'
ensure_line "$COMMON_ACCOUNT" 'account required pam_faillock.so'

log 'Hardening SSH authentication...'
if [ -f "$SSHD" ]; then
    set_sshd_option PermitRootLogin no
    set_sshd_option PasswordAuthentication no
    set_sshd_option PubkeyAuthentication yes
    set_sshd_option KbdInteractiveAuthentication no
    set_sshd_option ChallengeResponseAuthentication no
    set_sshd_option X11Forwarding no
    set_sshd_option MaxAuthTries 3
    set_sshd_option UsePAM yes
    if command -v sshd >/dev/null 2>&1 && ! sshd -t; then
        fail 'sshd configuration validation failed'
    fi
else
    fail "$SSHD does not exist"
fi

log 'Applying password aging defaults...'
if [ -f "$LOGIN_DEFS" ]; then
    set_login_value() {
        key=$1
        value=$2
        if grep -Eq "^[[:space:]]*${key}[[:space:]]+" "$LOGIN_DEFS"; then
            sed -i -E "s|^[[:space:]]*${key}[[:space:]]+.*$|${key} ${value}|" "$LOGIN_DEFS"
        else
            printf '%s %s\n' "$key" "$value" >> "$LOGIN_DEFS"
        fi
    }
    set_login_value PASS_MAX_DAYS 90
    set_login_value PASS_MIN_DAYS 1
    set_login_value PASS_WARN_AGE 14
fi

while IFS=: read -r username _ uid _ _ _ shell; do
    case "$uid" in
        ''|*[!0-9]*) continue ;;
    esac
    if [ "$uid" -ge 1000 ] && [ "$username" != nobody ] && \
        [ "$shell" != /usr/sbin/nologin ] && [ "$shell" != /bin/false ] && \
        command -v chage >/dev/null 2>&1; then
        chage -M 90 -m 1 -W 14 "$username" >/dev/null 2>&1 ||
            fail "could not apply password aging to $username"
    fi
done < /etc/passwd

log 'Locking the root account...'
if command -v passwd >/dev/null 2>&1; then
    passwd -l root >/dev/null 2>&1 || fail 'could not lock root account'
else
    fail 'passwd is not installed'
fi

if [ "$failures" -eq 0 ]; then
    log 'Identity hardening completed successfully.'
    exit 0
fi

log "Identity hardening completed with $failures error(s)."
exit 1
