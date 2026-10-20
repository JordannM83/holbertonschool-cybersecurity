#!/bin/bash
set -u

printf '%s\n\n' '=== Legal Banner Configuration ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then printf '%s\n' 'ERROR: configuring the SSH banner requires root privileges.'; exit 1; fi
config=/etc/ssh/sshd_config
banner=/etc/issue.net
[[ -f "$config" ]] || { printf 'ERROR: %s was not found.\n' "$config"; exit 1; }
if [[ -f "$banner" ]]; then cp -p -- "$banner" "$banner.backup.$(date +%Y%m%d-%H%M%S)" || exit 1; fi
cp -p -- "$config" "$config.backup.$(date +%Y%m%d-%H%M%S)" || exit 1

printf '%s\n' 'Creating banner in /etc/issue.net...'
printf '%s\n' '=====================================' 'AUTHORIZED ACCESS ONLY' '' 'This system is the property of NovaTech Solutions.' 'Unauthorized access is prohibited and will be prosecuted.' 'All activities are monitored and logged.' '=====================================' > "$banner"
chmod 0644 "$banner"
printf '\n%s\n' 'Banner content:'
cat "$banner"

tmp=$(mktemp "${config}.tmp.XXXXXX") || exit 1
awk '
    /^[[:space:]]*#/ { print; next }
    /^[[:space:]]*Banner[[:space:]]/ {
        if (!changed) { print "Banner /etc/issue.net"; changed=1 }
        next
    }
    { print }
    END { if (!changed) print "Banner /etc/issue.net" }
' "$config" > "$tmp"
chmod --reference="$config" "$tmp" 2>/dev/null || true
chown --reference="$config" "$tmp" 2>/dev/null || true
mv -- "$tmp" "$config" || exit 1
printf '\n%s\n' 'Configuring SSH to display banner...'
printf '  Banner /etc/issue.net: Enabled\n\n'
printf '%s\n' 'Reloading SSH...'
if command -v sshd >/dev/null 2>&1 && ! sshd -t -f "$config" 2>/dev/null; then printf '%s\n' 'ERROR: SSH configuration test failed.'; exit 1; fi
if command -v systemctl >/dev/null 2>&1; then
    systemctl reload sshd.service 2>/dev/null || systemctl reload ssh.service 2>/dev/null || exit 1
elif command -v service >/dev/null 2>&1; then
    service ssh reload >/dev/null 2>&1 || service sshd reload >/dev/null 2>&1 || exit 1
else
    printf '%s\n' 'ERROR: no SSH service manager found.'
    exit 1
fi

printf '\n%s\n' 'Verification:'
[[ -f "$banner" ]] && printf '  /etc/issue.net: EXISTS ✓\n' || exit 1
if sshd -T -f "$config" 2>/dev/null | grep -Eiq '^banner[[:space:]]+/etc/issue\.net([[:space:]]|$)'; then printf '  SSH Banner config: ENABLED ✓\n'
else printf '  SSH Banner config: NOT ENABLED\n'; exit 1; fi
printf '\n%s\n' 'Legal banner configured.'

