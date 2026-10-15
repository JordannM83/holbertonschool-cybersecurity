#!/bin/bash
# Remove vsftpd and verify that its vulnerable service is gone.
set -u

printf '%s\n\n' '=== Vulnerable Service Removal ==='
printf '%s\n\n' 'Target: vsftpd (CVE-2011-2523 - Backdoor)'

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: removing vsftpd requires root privileges.'
    exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: apt-get is required.'
    exit 1
fi

failed=0
printf '%s\n' 'Stopping service...'
stopped=0
if command -v systemctl >/dev/null 2>&1; then
    if systemctl stop vsftpd.service 2>/dev/null || ! systemctl is-active --quiet vsftpd.service 2>/dev/null; then stopped=1; fi
elif command -v service >/dev/null 2>&1; then
    if service vsftpd stop >/dev/null 2>&1 || ! service vsftpd status >/dev/null 2>&1; then stopped=1; fi
else
    stopped=1
fi
if ((stopped)); then printf '  vsftpd.service: Stopped\n'; else printf '  vsftpd.service: FAILED to stop\n'; failed=1; fi

printf '\n%s\n' 'Removing package...'
if apt-get purge -y vsftpd >/dev/null 2>&1; then
    printf '  vsftpd: Purged (including config files)\n'
else
    printf '  vsftpd: FAILED to purge\n'
    failed=1
fi

printf '\n%s\n' 'Cleanup...'
for config in /etc/vsftpd.conf /etc/vsftpd.user_list; do
    if [[ ! -e "$config" ]] || rm -f -- "$config"; then
        printf '  %s: Removed\n' "$config"
    else
        printf '  %s: FAILED to remove\n' "$config"
        failed=1
    fi
done
if [[ -d /etc/vsftpd ]]; then
    if rmdir --ignore-fail-on-non-empty /etc/vsftpd 2>/dev/null; then
        printf '  /etc/vsftpd: Removed\n'
    else
        printf '  /etc/vsftpd: Not empty (review manually)\n'
    fi
fi

printf '\n%s\n' 'Verification:'
package_status='Not installed'
if command -v dpkg-query >/dev/null 2>&1; then
    dpkg_state=$(dpkg-query -W -f='${db:Status-Status}' vsftpd 2>/dev/null || true)
    if [[ -n "$dpkg_state" && "$dpkg_state" != 'not-installed' && "$dpkg_state" != 'config-files' ]]; then
        package_status='Still installed'
        failed=1
    fi
fi
printf '  Package status: %s\n' "$package_status"

port_status='Not listening'
if command -v ss >/dev/null 2>&1 && ss -H -ltnup 2>/dev/null | grep -Eq '(^|[[:space:]])[^[:space:]]*(:|\])21[[:space:]]'; then
    port_status='LISTENING'
elif command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:21 -sTCP:LISTEN 2>/dev/null | grep -q .; then
    port_status='LISTENING'
fi
[[ "$port_status" == 'Not listening' ]] || failed=1
printf '  Port 21: %s\n' "$port_status"

if (( ! failed )); then
    printf '\n%s\n' 'vsftpd removed successfully.'
    printf '%s\n' 'Vulnerability CVE-2011-2523: REMEDIATED'
    exit 0
fi

printf '\n%s\n' 'vsftpd removal incomplete; remediation requires further action.'
exit 1
