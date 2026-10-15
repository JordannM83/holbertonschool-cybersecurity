#!/bin/bash
# Read-only verification of the lifecycle-defense remediation findings.
set -u

printf '%s\n\n' '=== Remediation Verification ==='
printf '%s\n\n' 'Checking vulnerabilities from assessment report...'
passed=0

report() {
    local level=$1 finding=$2 result=$3 detail=$4
    printf '[%s] %s\n' "$level" "$finding"
    printf '  Status: %s (%s)\n\n' "$result" "$detail"
    [[ "$result" == REMEDIATED* ]] && passed=$((passed + 1))
}

vsftpd_ok=1
if command -v dpkg-query >/dev/null 2>&1; then
    state=$(dpkg-query -W -f='${db:Status-Status}' vsftpd 2>/dev/null || true)
    [[ -n "$state" && "$state" != not-installed && "$state" != config-files ]] && vsftpd_ok=0
fi
if command -v ss >/dev/null 2>&1 && ss -H -ltnup 2>/dev/null | grep -Eq '(^|[[:space:]])[^[:space:]]*(:|\])21[[:space:]]'; then vsftpd_ok=0; fi
if ((vsftpd_ok)); then report CRITICAL 'CVE-2011-2523 vsftpd backdoor' REMEDIATED 'service removed'
else report CRITICAL 'CVE-2011-2523 vsftpd backdoor' FAILED 'service or package remains'
fi

apache_ok=0
if command -v apache2 >/dev/null 2>&1; then
    apache_version=$(apache2 -v 2>/dev/null | sed -n 's/^Server version: Apache\/\([^ ]*\).*/\1/p')
    if [[ -n "$apache_version" ]] && command -v dpkg >/dev/null 2>&1 && dpkg --compare-versions "$apache_version" ge 2.4.41; then apache_ok=1; fi
fi
if ((apache_ok)); then report HIGH 'Apache outdated (CVE-2021-*)' REMEDIATED "version $apache_version"
else report HIGH 'Apache outdated (CVE-2021-*)' FAILED 'outdated or unavailable'
fi

ssh_config=/etc/ssh/sshd_config
ssh_values=''
if command -v sshd >/dev/null 2>&1; then ssh_values=$(sshd -T -f "$ssh_config" 2>/dev/null || true); fi
[[ -z "$ssh_values" && -r "$ssh_config" ]] && ssh_values=$(grep -Ei '^[[:space:]]*(PermitRootLogin|PasswordAuthentication)[[:space:]]+' "$ssh_config" 2>/dev/null || true)
if grep -Eiq '^[[:space:]]*permitrootlogin[[:space:]]+no([[:space:]]|$)' <<< "$ssh_values" && grep -Eiq '^[[:space:]]*passwordauthentication[[:space:]]+no([[:space:]]|$)' <<< "$ssh_values"; then
    report HIGH 'SSH PermitRootLogin enabled' REMEDIATED 'set to no'
else report HIGH 'SSH PermitRootLogin enabled' FAILED 'SSH hardening not confirmed'
fi

mysql_secret=/root/.mysql_secret
mysql_ok=0
if [[ -s "$mysql_secret" && "$(stat -c '%a' "$mysql_secret" 2>/dev/null || true)" == 600 ]] && command -v mysql >/dev/null 2>&1; then
    MYSQL_PWD=$(cat "$mysql_secret") mysql --protocol=socket -uroot -e 'SELECT 1' >/dev/null 2>&1 && mysql_ok=1
fi
if ((mysql_ok)); then report HIGH 'MySQL root no password' REMEDIATED 'password set'
else report HIGH 'MySQL root no password' FAILED 'password authentication not confirmed'
fi

mysql_config=/etc/mysql/mysql.conf.d/mysqld.cnf
bind_ok=0
grep -Eiq '^[[:space:]]*bind-address[[:space:]]*=[[:space:]]*127\.0\.0\.1([[:space:]]|$)' "$mysql_config" 2>/dev/null && bind_ok=1
if command -v ss >/dev/null 2>&1 && ss -H -ltn 2>/dev/null | grep -Eq '(^|[[:space:]])(0\.0\.0\.0|\*|\[::\]):3306[[:space:]]'; then bind_ok=0; fi
if ((bind_ok)); then report HIGH 'MySQL exposed to network' REMEDIATED 'localhost only'
else report HIGH 'MySQL exposed to network' FAILED 'network exposure not excluded'
fi

suid_ok=0
if [[ -e /usr/local/bin/backup ]] && ! find /usr/local/bin/backup -perm /6000 -print -quit 2>/dev/null | grep -q .; then suid_ok=1; fi
if ((suid_ok)); then report MEDIUM 'SUID binary /usr/local/bin/backup' REMEDIATED 'SUID removed'
else report MEDIUM 'SUID binary /usr/local/bin/backup' FAILED 'SUID/SGID remains or file missing'
fi

cron_ok=0
if [[ -e /etc/cron.daily/backup.sh ]] && ! find /etc/cron.daily/backup.sh -perm -0002 -print -quit 2>/dev/null | grep -q .; then cron_ok=1; fi
if ((cron_ok)); then report MEDIUM 'World-writable cron script' REMEDIATED 'permissions fixed'
else report MEDIUM 'World-writable cron script' FAILED 'world-writable or missing'
fi

credentials_ok=0
if [[ -L /var/www/html/.env && "$(readlink /var/www/html/.env 2>/dev/null)" == /etc/novatech/app.env && -f /etc/novatech/app.env ]]; then credentials_ok=1; fi
if ((credentials_ok)); then report MEDIUM 'Exposed credentials in webroot' REMEDIATED 'moved to /etc'
else report MEDIUM 'Exposed credentials in webroot' FAILED 'credential relocation not confirmed'
fi

printf 'Summary: %s/8 vulnerabilities remediated\n' "$passed"
if [[ "$passed" -eq 8 ]]; then
    printf '%s\n' 'System ready for patch automation.'
    exit 0
fi
printf '%s\n' 'System is not ready for patch automation.'
exit 1
