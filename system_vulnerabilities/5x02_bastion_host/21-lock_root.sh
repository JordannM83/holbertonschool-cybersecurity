#!/bin/bash
# Lock the root password after confirming sudo remains usable.
set -u

printf '%s\n\n' '=== Root Account Lockdown ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then printf '%s\n' 'ERROR: locking root requires root privileges.'; exit 1; fi
if ! command -v sudo >/dev/null 2>&1 || ! command -v passwd >/dev/null 2>&1; then printf '%s\n' 'ERROR: sudo and passwd are required.'; exit 1; fi

printf '%s\n' 'Pre-flight checks:'
sudo_ok=0
if sudo -n -v >/dev/null 2>&1 && sudo -n -u root true >/dev/null 2>&1; then sudo_ok=1; printf '  Current user has sudo: YES ✓\n'; else printf '  Current user has sudo: NO\n'; fi
sudoers_ok=0
if command -v visudo >/dev/null 2>&1 && visudo -c >/dev/null 2>&1; then sudoers_ok=1; printf '  Sudo configuration valid: YES ✓\n'; else printf '  Sudo configuration valid: NO\n'; fi
if (( ! sudo_ok || ! sudoers_ok )); then printf '%s\n' 'ERROR: pre-flight checks failed; root was not locked.'; exit 1; fi

printf '\n%s\n' 'Locking root account...'
if passwd -l root >/dev/null 2>&1; then printf '  passwd -l root: Done\n'; else printf '  passwd -l root: FAILED\n'; exit 1; fi

printf '\n%s\n' 'Verification:'
root_status=$(passwd -S root 2>/dev/null || true)
if [[ "$root_status" =~ [[:space:]](L|LK)[[:space:]] ]]; then printf '  Root password: LOCKED (!)\n'; else printf '  Root password: NOT LOCKED\n'; exit 1; fi
ssh_status='Unknown'
if command -v sshd >/dev/null 2>&1; then
    sshd_config=$(sshd -T 2>/dev/null || true)
    grep -Eiq '^permitrootlogin[[:space:]]+no([[:space:]]|$)' <<< "$sshd_config" && ssh_status='Already disabled (PermitRootLogin no)'
elif [[ -r /etc/ssh/sshd_config ]] && grep -Eiq '^[[:space:]]*PermitRootLogin[[:space:]]+no' /etc/ssh/sshd_config; then
    ssh_status='Already disabled (PermitRootLogin no)'
fi
printf '  Root SSH login: %s\n' "$ssh_status"
if sudo -n -u root true >/dev/null 2>&1; then printf '  Sudo to root: WORKING ✓\n'; else printf '  Sudo to root: FAILED\n'; exit 1; fi

printf '\n%s\n' 'WARNING: Direct root login is now impossible.'
printf '%s\n' 'All administrative tasks must use sudo.'
