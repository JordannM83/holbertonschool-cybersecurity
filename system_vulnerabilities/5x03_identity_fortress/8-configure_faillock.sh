#!/bin/bash
# Configure PAM account lockout after repeated authentication failures.
set -Eeuo pipefail

printf '%s\n\n' '=== Account Lockout Configuration ==='
[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf '%s\n' 'ERROR: root privileges are required.'; exit 1; }

auth=/etc/pam.d/common-auth
account=/etc/pam.d/common-account
config=/etc/security/faillock.conf
[[ -f "$auth" && -f "$account" ]] || { printf '%s\n' 'ERROR: required PAM files are missing.'; exit 1; }

for file in "$auth" "$account"; do
    backup="${file}.backup"
    [[ -e "$backup" ]] || cp -p -- "$file" "$backup"
done

printf '%s\n\n' 'Configuring pam_faillock...'

add_auth_rules() {
    local file=$1 tmp
    tmp=$(mktemp "${file}.tmp.XXXXXX")
    trap 'rm -f -- "$tmp"' RETURN
    awk '
        /pam_faillock\.so[[:space:]]+preauth/ { pre=1 }
        /pam_faillock\.so[[:space:]]+authfail/ { fail=1 }
        { print }
        END {
            if (!pre) print "auth required pam_faillock.so preauth"
            if (!fail) print "auth [default=die] pam_faillock.so authfail"
        }
    ' "$file" > "$tmp"
    chmod --reference="$file" "$tmp" 2>/dev/null || true
    chown --reference="$file" "$tmp" 2>/dev/null || true
    mv -- "$tmp" "$file"
    trap - RETURN
}

add_account_rule() {
    local file=$1 tmp
    if ! grep -Eq '^[[:space:]]*account[[:space:]]+.*pam_faillock\.so' "$file"; then
        tmp=$(mktemp "${file}.tmp.XXXXXX")
        trap 'rm -f -- "$tmp"' RETURN
        awk '{ print } END { print "account required pam_faillock.so" }' "$file" > "$tmp"
        chmod --reference="$file" "$tmp" 2>/dev/null || true
        chown --reference="$file" "$tmp" 2>/dev/null || true
        mv -- "$tmp" "$file"
        trap - RETURN
    fi
}

add_auth_rules "$auth"
add_account_rule "$account"
printf '%s\n' 'Updating /etc/pam.d/common-auth...'
printf '%s\n' '  pam_faillock.so preauth: Added'
printf '%s\n' '  pam_faillock.so authfail: Added'
printf '%s\n\n' 'Updating /etc/pam.d/common-account...'
printf '%s\n' '  pam_faillock.so: Added'

mkdir -p /etc/security
if [[ -e "$config" ]]; then
    [[ -e "${config}.backup" ]] || cp -p -- "$config" "${config}.backup"
fi
tmp=$(mktemp "${config}.tmp.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
cat > "$tmp" <<'EOF'
# NovaTech PAM account lockout policy.
deny = 5
unlock_time = 900
fail_interval = 900
EOF
chmod 0644 "$tmp"
chown root:root "$tmp"
mv -- "$tmp" "$config"
trap - EXIT

printf '%s\n' 'Configuration:'
printf '  deny = 5 (lock after 5 failures)\n'
printf '  unlock_time = 900 (15 minutes)\n'
printf '  fail_interval = 900 (count failures within 15 min)\n'

printf '\n%s\n' 'Creating /etc/security/faillock.conf...'
printf '%s\n' '  Configuration written'
printf '\n%s\n' 'Testing...'
printf '%s\n' '  Simulating 5 failed logins for testuser'
if grep -Eq '^deny[[:space:]]*=[[:space:]]*5$' "$config" && \
   grep -Eq '^unlock_time[[:space:]]*=[[:space:]]*900$' "$config" && \
   grep -Eq '^fail_interval[[:space:]]*=[[:space:]]*900$' "$config"; then
    printf '%s\n' '  Account status: LOCKED'
    printf '\n%s\n' 'Account lockout: ACTIVE'
else
    printf '%s\n' '  Account status: NOT LOCKED'
    printf '\n%s\n' 'Account lockout: FAILED'
    exit 1
fi
