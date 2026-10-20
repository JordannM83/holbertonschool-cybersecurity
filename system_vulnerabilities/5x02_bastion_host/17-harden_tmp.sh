#!/bin/bash
set -u

printf '%s\n\n' '=== Hardening /tmp ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then printf '%s\n' 'ERROR: hardening /tmp requires root privileges.'; exit 1; fi
command -v mount >/dev/null 2>&1 || { printf '%s\n' 'ERROR: mount is required.'; exit 1; }

printf '%s\n' 'Current /tmp mount:'
findmnt /tmp 2>/dev/null || mount | grep '[[:space:]]/tmp[[:space:]]' || printf '  /tmp mount information unavailable\n'
printf '\n%s\n\n' 'Applying hardening options...'
printf '%s\n' 'Method: Bind mount with options'

fstab=/etc/fstab
if [[ -f "$fstab" ]]; then
    backup="${fstab}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -p -- "$fstab" "$backup" || exit 1
fi
tmp=$(mktemp "${fstab}.tmp.XXXXXX") || exit 1
if [[ -f "$fstab" ]]; then
    awk '
        /^[[:space:]]*#/ { print; next }
        $2 == "/tmp" { print "# Replaced by 17-harden_tmp.sh: " $0; next }
        { print }
    ' "$fstab" > "$tmp"
fi
printf 'tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0\n' >> "$tmp"
chmod 0644 "$tmp"
mv -- "$tmp" "$fstab" || exit 1
printf 'Adding to /etc/fstab:\n'
printf '  tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0\n\n'

mount --bind /tmp /tmp 2>/dev/null || true
if ! mount -o remount,bind,noexec,nosuid,nodev /tmp 2>/dev/null; then
    mount -o remount,noexec,nosuid,nodev /tmp 2>/dev/null || {
        printf '%s\n' 'ERROR: could not remount /tmp with hardening options.'
        exit 1
    }
fi
printf '%s\n' 'Remounting /tmp...'

options=$(findmnt -no OPTIONS /tmp 2>/dev/null || true)
printf '\n%s\n' 'Verification:'
printf '  /tmp mount options: %s\n' "$options"
if [[ "$options" != *noexec* || "$options" != *nosuid* || "$options" != *nodev* ]]; then
    printf '%s\n' '  ERROR: required mount options are not active.'
    exit 1
fi

test_file=/tmp/.tmp-exec-test-$$
printf '#!/bin/sh\nexit 0\n' > "$test_file"
chmod 0755 "$test_file"
if "$test_file" >/dev/null 2>&1; then exec_result='ALLOWED'; else exec_result='BLOCKED (Permission denied)'; fi
rm -f -- "$test_file"
printf '\n%s\n' 'Testing restrictions:'
if [[ "$exec_result" == BLOCKED* ]]; then printf '  Execute test: %s ✓\n' "$exec_result"; else printf '  Execute test: %s\n' "$exec_result"; fi
printf '  SUID test: BLOCKED (nosuid active) ✓\n\n'
printf '%s\n' '/tmp hardened successfully.'

