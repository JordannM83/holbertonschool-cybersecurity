#!/bin/bash
# List package holds and release them when their exception is resolved.
set -u

log=/var/log/package_holds.log
if [[ $# -lt 1 ]]; then
    printf 'Usage: %s list | release PACKAGE\n' "$(basename "$0")"
    exit 2
fi
action=$1

if ! command -v apt-mark >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: apt-mark is required.'
    exit 1
fi

case "$action" in
    list)
        printf '%s\n\n' '=== Package Hold Registry ==='
        printf '%-16s %-12s %-12s %-5s %s\n' 'Package' 'Version' 'Held Since' 'Days' 'Reason'
        total=0; older=0; now=$(date +%s)
        holds=$(apt-mark showhold 2>/dev/null || true)
        if [[ -n "$holds" && -r "$log" ]]; then
            while IFS=$'\t' read -r held_at package version review reason; do
                [[ -n "$package" ]] || continue
                grep -qx "$package" <<< "$holds" || continue
                held_epoch=$(date -d "$held_at" +%s 2>/dev/null || true)
                [[ "$held_epoch" =~ ^[0-9]+$ ]] || continue
                days=$(( (now - held_epoch) / 86400 )); ((days < 0)) && days=0
                printf '%-16s %-12s %-12s %-5s %s\n' "$package" "$version" "${held_at%% *}" "$days" "$reason"
                total=$((total + 1)); ((days > 14)) && older=$((older + 1))
            done < "$log"
        fi
        printf '\nTotal holds: %s\n' "$total"
        printf 'Holds older than 14 days: %s\n' "$older"
        ;;
    release)
        if [[ $# -ne 2 ]]; then printf 'Usage: %s release PACKAGE\n' "$(basename "$0")"; exit 2; fi
        [[ ${EUID:-$(id -u)} -eq 0 ]] || { printf '%s\n' 'ERROR: releasing a hold requires root privileges.'; exit 1; }
        package=$2
        printf 'Releasing hold on %s...\n' "$package"
        if apt-mark unhold "$package" >/dev/null; then printf '  apt-mark unhold %s: Done\n' "$package"; else printf '  apt-mark unhold %s: FAILED\n' "$package"; exit 1; fi
        if [[ -f "$log" ]]; then
            tmp=$(mktemp "${log}.tmp.XXXXXX") || exit 1
            awk -F '\t' -v package="$package" '$2 != package' "$log" > "$tmp"
            chmod --reference="$log" "$tmp" 2>/dev/null || true
            if mv -- "$tmp" "$log"; then printf '  Removed from %s\n' "$log"; else rm -f -- "$tmp"; printf '  Failed to update %s\n' "$log"; exit 1; fi
        else
            printf '  No registry entry found at %s\n' "$log"
        fi
        printf '\n%s\n' 'Package will be upgraded on next automatic cycle.'
        ;;
    *)
        printf 'Usage: %s list | release PACKAGE\n' "$(basename "$0")"
        exit 2
        ;;
esac
