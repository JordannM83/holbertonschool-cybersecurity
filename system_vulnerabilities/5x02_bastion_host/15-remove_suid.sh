#!/bin/bash
set -u

printf '%s\n\n' '=== SUID Neutralization ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then printf '%s\n' 'ERROR: SUID neutralization requires root privileges.'; exit 1; fi

essential=(/usr/bin/sudo /usr/bin/passwd /usr/bin/su)
targets=(/usr/bin/mount /usr/bin/umount /usr/bin/newgrp /usr/local/bin/backup)
before=$(find / -xdev -type f -perm /4000 -print 2>/dev/null | wc -l)

printf '%s\n' 'Preserving essential SUID (DO NOT TOUCH):'
for binary in "${essential[@]}"; do printf '  %s\n' "$binary"; done

printf '\n%s\n' 'Removing SUID from non-essential binaries...'
failed=0
for binary in "${targets[@]}"; do
    [[ -e "$binary" ]] || continue
    case "$binary" in
        /usr/bin/mount|/usr/bin/umount) reason='admin can use sudo' ;;
        /usr/bin/newgrp) reason='not needed' ;;
        /usr/local/bin/backup) reason='CUSTOM - HIGH RISK' ;;
    esac
    old=$(stat -c '%a' "$binary" 2>/dev/null || printf 'unknown')
    if chmod u-s -- "$binary"; then
        printf '  %s: SUID removed (%s; was %s)\n' "$binary" "$reason" "$old"
    else
        printf '  %s: FAILED to remove SUID\n' "$binary"
        failed=1
    fi
done

printf '\n%s\n' 'Verification:'
for binary in /usr/bin/mount /usr/bin/umount; do
    if [[ -e "$binary" ]]; then
        mode=$(stat -Lc '%A' "$binary" 2>/dev/null || printf 'unknown')
        if find "$binary" -perm /4000 -print -quit 2>/dev/null | grep -q .; then
            printf '  %s: %s (SUID STILL PRESENT)\n' "${binary##*/}" "$mode"
            failed=1
        else
            printf '  %s: %s (no SUID)\n' "${binary##*/}" "$mode"
        fi
    fi
done
after=$(find / -xdev -type f -perm /4000 -print 2>/dev/null | wc -l)
printf '\nSUID binaries reduced from %s to %s.\n' "$before" "$after"
if (( ! failed )); then exit 0; fi
exit 1

