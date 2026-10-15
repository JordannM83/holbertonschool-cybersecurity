#!/bin/bash
set -u

printf '%s\n\n' '=== Permission Remediation ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: permission remediation requires root privileges.'
    exit 1
fi
failed=0
mode_of() { stat -c '%a' -- "$1" 2>/dev/null || printf 'unknown'; }
mode_display() { [[ "$1" =~ ^[0-9]+$ ]] && printf '%04d' "$1" || printf '%s' "$1"; }

printf '%s\n' 'SUID/SGID issues:'
suid=/usr/local/bin/backup
if [[ -e "$suid" ]]; then
    old=$(mode_of "$suid")
    if chmod u-s,g-s -- "$suid"; then
        printf '  %s: SUID removed (was %s, now %s)\n' "$suid" "$(mode_display "$old")" "$(mode_display "$(mode_of "$suid")")"
    else
        printf '  %s: FAILED\n' "$suid"; failed=1
    fi
else printf '  %s: Not present\n' "$suid"; fi

printf '\n%s\n' 'World-writable files:'
for file in /etc/cron.daily/backup.sh /opt/scripts/cleanup.sh; do
    if [[ -e "$file" ]]; then
        old=$(mode_of "$file")
        if chmod 0755 -- "$file"; then printf '  %s: %s -> 0755\n' "$file" "$(mode_display "$old")"
        else printf '  %s: FAILED\n' "$file"; failed=1; fi
    else printf '  %s: Not present\n' "$file"; fi
done

printf '\n%s\n' 'Sensitive file permissions:'
config=/var/www/html/config.php
if [[ -e "$config" ]]; then
    old=$(mode_of "$config")
    if chmod 0640 -- "$config" && chown www-data -- "$config" 2>/dev/null; then
        printf '  %s: %s -> 0640 (owner www-data)\n' "$config" "$(mode_display "$old")"
    else printf '  %s: FAILED\n' "$config"; failed=1; fi
else printf '  %s: Not present\n' "$config"; fi
key=/home/devops/.ssh/id_rsa
if [[ -e "$key" ]]; then
    old=$(mode_of "$key")
    if chmod 0600 -- "$key"; then printf '  %s: %s -> 0600\n' "$key" "$(mode_display "$old")"
    else printf '  %s: FAILED\n' "$key"; failed=1; fi
else printf '  %s: Not present\n' "$key"; fi

printf '\n%s\n' 'Credential exposure:'
env_file=/var/www/html/.env
env_target=/etc/novatech/app.env
if [[ -e "$env_file" && ! -L "$env_file" ]]; then
    if [[ -e "$env_target" ]]; then
        printf '  %s: destination already exists; not overwritten\n' "$env_target"; failed=1
    elif mkdir -p /etc/novatech && mv -- "$env_file" "$env_target"; then
        chmod 0640 -- "$env_target" || failed=1
        printf '  %s: Moved to %s\n' "$env_file" "$env_target"
    else printf '  %s: FAILED to move\n' "$env_file"; failed=1; fi
fi
if [[ -L "$env_file" && "$(readlink "$env_file")" == "$env_target" ]]; then
    printf '  Symlink already present for application compatibility\n'
elif [[ ! -e "$env_file" && -e "$env_target" ]]; then
    if ln -s -- "$env_target" "$env_file"; then printf '  Symlink created for application compatibility\n'
    else printf '  Symlink creation FAILED\n'; failed=1; fi
elif [[ -e "$env_file" ]]; then
    printf '  %s: compatibility link not created\n' "$env_file"; failed=1
else printf '  %s: Not present\n' "$env_file"; fi

if (( ! failed )); then
    printf '\n%s\n' 'All permission issues remediated.'
    exit 0
fi
printf '\n%s\n' 'Permission remediation incomplete; review the failures above.'
exit 1
