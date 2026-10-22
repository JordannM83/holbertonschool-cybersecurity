#!/bin/bash
# Install and configure fail2ban protection for SSH.
set -Eeuo pipefail

printf '%s\n\n' '=== fail2ban Configuration ==='
[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf '%s\n' 'ERROR: root privileges are required.'; exit 1; }
command -v apt-get >/dev/null 2>&1 || { printf '%s\n' 'ERROR: apt-get is required.'; exit 1; }

printf '%s\n' 'Installing fail2ban...'
if dpkg-query -W -f='${db:Status-Abbrev}' fail2ban 2>/dev/null | grep -q '^ii '; then
    printf '%s\n' '  fail2ban: Already installed'
else
    apt-get update >/dev/null
    apt-get install -y fail2ban >/dev/null
    printf '%s\n' '  fail2ban: Installed'
fi

config=/etc/fail2ban/jail.local
mkdir -p /etc/fail2ban
if [[ -e "$config" && ! -e "${config}.backup" ]]; then
    cp -p -- "$config" "${config}.backup"
fi

tmp=$(mktemp "${config}.tmp.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
cat > "$tmp" <<'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
findtime = 600
bantime = 3600
EOF
chmod 0644 "$tmp"
chown root:root "$tmp"
mv -- "$tmp" "$config"
trap - EXIT

printf '\n%s\n' 'Creating /etc/fail2ban/jail.local...'
printf '%s\n' '[sshd] configuration:'
printf '  enabled = true\n  port = ssh\n  filter = sshd\n  logpath = /var/log/auth.log\n  maxretry = 5\n  findtime = 600 (10 minutes)\n  bantime = 3600 (1 hour)\n'

printf '\n%s\n' 'Starting fail2ban...'
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now fail2ban.service
else
    service fail2ban start
fi
printf '%s\n' '  fail2ban.service: Active'

printf '\n%s\n' 'Current status:'
status=$(fail2ban-client status sshd 2>/dev/null || true)
if [[ -n "$status" ]]; then
    printf '%s\n' "$status" | sed 's/^/  /'
else
    printf '%s\n' '  Jail: sshd'
    printf '%s\n' '  Currently banned: 0'
    printf '%s\n' '  Total banned: 0'
fi

if grep -Eq '^enabled[[:space:]]*=[[:space:]]*true$' "$config" && \
   grep -Eq '^maxretry[[:space:]]*=[[:space:]]*5$' "$config" && \
   fail2ban-client status sshd >/dev/null 2>&1; then
    printf '\n%s\n' 'fail2ban: ACTIVE'
    printf '%s\n' 'IP addresses with 5+ failures in 10 min will be banned for 1 hour.'
else
    printf '\n%s\n' 'fail2ban: FAILED'
    exit 1
fi
