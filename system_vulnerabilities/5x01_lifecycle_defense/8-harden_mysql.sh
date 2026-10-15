#!/bin/bash
# Harden MySQL configuration and account defaults.
set -u

printf '%s\n\n' '=== MySQL Hardening ==='

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: MySQL hardening requires root privileges.'
    exit 1
fi
if ! command -v mysql >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: mysql client was not found.'
    exit 1
fi

config=/etc/mysql/mysql.conf.d/mysqld.cnf
if [[ ! -f "$config" ]]; then
    printf 'ERROR: %s was not found.\n' "$config"
    exit 1
fi

today=$(date +%Y%m%d)
backup="${config}.backup.${today}"
[[ -e "$backup" ]] && backup="${config}.backup.$(date +%Y%m%d-%H%M%S)"
if ! cp -p -- "$config" "$backup"; then
    printf '%s\n' 'ERROR: could not create MySQL configuration backup.'
    exit 1
fi
printf 'Backup created: %s\n\n' "$backup"

secret_file=/root/.mysql_secret
old_password=''
[[ -r "$secret_file" ]] && old_password=$(cat "$secret_file")
umask 077
password=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)
if [[ ${#password} -lt 32 ]]; then
    printf '%s\n' 'ERROR: could not generate a strong root password.'
    exit 1
fi
if ! printf '%s\n' "$password" > "$secret_file"; then
    printf '%s\n' 'ERROR: could not store the MySQL secret.'
    exit 1
fi
chmod 600 "$secret_file"

tmp=$(mktemp "${config}.tmp.XXXXXX") || exit 1
trap 'rm -f -- "$tmp"' EXIT
awk -v value='127.0.0.1' '
    BEGIN { changed=0 }
    /^[[:space:]]*bind-address[[:space:]]*=/ {
        if (!changed) { print "bind-address = " value; changed=1 }
        next
    }
    { print }
    END { if (!changed) print "bind-address = " value }
' "$config" > "$tmp"
chmod --reference="$config" "$tmp" 2>/dev/null || true
chown --reference="$config" "$tmp" 2>/dev/null || true
if ! mv -- "$tmp" "$config"; then
    printf '%s\n' 'ERROR: could not update MySQL configuration.'
    exit 1
fi
tmp=$(mktemp "${config}.tmp.XXXXXX") || exit 1

printf '%s\n' 'Securing MySQL...'
sql="ALTER USER 'root'@'localhost' IDENTIFIED BY '$password';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db LIKE 'test%';
FLUSH PRIVILEGES;"

mysql_ok=0
if mysql --protocol=socket -uroot -e "$sql" >/dev/null 2>&1; then
    mysql_ok=1
elif [[ -n "$old_password" ]] && MYSQL_PWD="$old_password" mysql --protocol=socket -uroot -e "$sql" >/dev/null 2>&1; then
    mysql_ok=1
fi
if (( ! mysql_ok )); then
    cp -p -- "$backup" "$config"
    printf '%s\n' 'ERROR: could not apply MySQL account hardening; configuration restored.'
    exit 1
fi

printf '  Root password: Set (stored in %s)\n' "$secret_file"
printf '  Anonymous users: Removed\n'
printf '  Remote root login: Disabled\n'
printf '  Test database: Removed\n'
printf '  Bind address: 0.0.0.0 -> 127.0.0.1\n'

printf '\n%s\n' 'Restarting MySQL...'
restarted=0
if command -v systemctl >/dev/null 2>&1; then
    systemctl restart mysql.service 2>/dev/null && restarted=1
elif command -v service >/dev/null 2>&1; then
    service mysql restart >/dev/null 2>&1 && restarted=1
fi
if (( ! restarted )); then
    printf '  mysql.service: FAILED to restart\n'
    exit 1
fi
printf '  mysql.service: Restarted\n'

printf '\n%s\n' 'Verification:'
if MYSQL_PWD=$(cat "$secret_file") mysql --protocol=socket -uroot -e 'SELECT 1' >/dev/null 2>&1; then
    printf '  Local root access: OK (with password)\n'
else
    printf '  Local root access: FAILED\n'
    exit 1
fi

remote='REFUSED (bind localhost only)'
if command -v ss >/dev/null 2>&1 && ss -H -ltn 2>/dev/null | grep -Eq '(^|[[:space:]])(0\.0\.0\.0|\*|\[::\]):3306[[:space:]]'; then
    remote='EXPOSED (not localhost-only)'
elif command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:3306 -sTCP:LISTEN 2>/dev/null | grep -Eq '[*]|0\.0\.0\.0:3306|\[::\]:3306'; then
    remote='EXPOSED (not localhost-only)'
fi
printf '  Remote connections: %s\n' "$remote"
if [[ "$remote" != REFUSED* ]]; then exit 1; fi

printf '\n%s\n' 'MySQL hardened successfully.'
