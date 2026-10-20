#!/bin/bash
set -u

printf '%s\n\n' '=== Hardening /var/tmp and /dev/shm ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then printf '%s\n' 'ERROR: hardening temporary directories requires root privileges.'; exit 1; fi
command -v mount >/dev/null 2>&1 || { printf '%s\n' 'ERROR: mount is required.'; exit 1; }

fstab=/etc/fstab
if [[ -f "$fstab" ]]; then
    backup="${fstab}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -p -- "$fstab" "$backup" || exit 1
fi
tmp=$(mktemp "${fstab}.tmp.XXXXXX") || exit 1
if [[ -f "$fstab" ]]; then
    awk '
        /^[[:space:]]*#/ { print; next }
        ($2 == "/var/tmp" || $2 == "/dev/shm") { print "# Replaced by 18-harden_other_tmp.sh: " $0; next }
        { print }
    ' "$fstab" > "$tmp"
fi

printf '%s\n' 'Hardening /var/tmp...'
printf '  Bind mount to /tmp (inherits restrictions)\n'
printf '/tmp /var/tmp none bind 0 0\n' >> "$tmp"
printf '%s\n' '  Added to /etc/fstab'
printf '%s\n' 'Hardening /dev/shm...'
current=$(findmnt -no FSTYPE,OPTIONS /dev/shm 2>/dev/null || printf 'unknown')
printf '  Current: %s\n' "$current"
printf '  Adding: noexec\n'
printf 'tmpfs /dev/shm tmpfs defaults,nosuid,nodev,noexec 0 0\n' >> "$tmp"
printf '%s\n' '  Updated in /etc/fstab'
chmod 0644 "$tmp"
mv -- "$tmp" "$fstab" || exit 1

printf '\n%s\n' 'Remounting...'
mount --bind /tmp /var/tmp 2>/dev/null || true
mount -o remount,bind,noexec,nosuid,nodev /var/tmp 2>/dev/null || mount -o remount,noexec,nosuid,nodev /var/tmp 2>/dev/null || exit 1
mount -o remount,noexec,nosuid,nodev /dev/shm 2>/dev/null || exit 1

var_options=$(findmnt -no OPTIONS /var/tmp 2>/dev/null || true)
shm_options=$(findmnt -no OPTIONS /dev/shm 2>/dev/null || true)
printf '\n%s\n' 'Verification:'
if [[ "$var_options" == *noexec* && "$var_options" == *nosuid* && "$var_options" == *nodev* ]]; then printf '  /var/tmp: noexec,nosuid,nodev ✓\n'; else printf '  /var/tmp: %s (FAILED)\n' "$var_options"; exit 1; fi
if [[ "$shm_options" == *noexec* && "$shm_options" == *nosuid* && "$shm_options" == *nodev* ]]; then printf '  /dev/shm: noexec,nosuid,nodev ✓\n'; else printf '  /dev/shm: %s (FAILED)\n' "$shm_options"; exit 1; fi
printf '\n%s\n' 'All temporary directories hardened.'

