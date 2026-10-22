#!/bin/bash
# View and reset PAM faillock records.
set -u

usage() {
    printf 'Usage: %s status | show USER | reset USER\n' "$(basename "$0")"
}

if [ "$#" -eq 0 ]; then
    usage
    exit 2
fi
if [ "$1" = "" ]; then
    usage
    exit 2
fi

command -v faillock >/dev/null 2>&1 || {
    printf '%s\n' 'ERROR: faillock is not installed or not in PATH.'
    exit 1
}

action=${1:-}
case "$action" in
    status)
        printf '%s\n\n' '=== Faillock Status ==='
        printf '%s\n' 'Locked accounts:'
        all_status=$(faillock --all 2>/dev/null || true)
        if [[ -n "$all_status" ]]; then
            printf '%s\n' "$all_status" | sed 's/^/  /'
        else
            printf '%s\n' '  None'
        fi
        ;;
    show)
        user=${2:-}
        [[ -n "$user" ]] || { usage; exit 2; }
        getent passwd "$user" >/dev/null 2>&1 || { printf 'ERROR: account not found: %s\n' "$user"; exit 1; }
        printf '=== Faillock Details: %s ===\n\n' "$user"
        printf '%s\n' 'Recent failures:'
        details=$(faillock --user "$2" 2>/dev/null || true)
        if [[ -n "$details" ]]; then
            printf '%s\n' "$details" | sed 's/^/  /'
        else
            printf '%s\n' '  No recorded failures.'
        fi
        printf '\n%s\n' 'Status:'
        if [[ -n "$details" ]]; then
            printf '%s\n' '  LOCKED or failures recorded'
        else
            printf '%s\n' '  UNLOCKED'
        fi
        ;;
    reset)
        user=${2:-}
        [[ -n "$user" ]] || { usage; exit 2; }
        [[ ${EUID:-$(id -u)} -eq 0 ]] || { printf '%s\n' 'ERROR: reset requires root privileges.'; exit 1; }
        getent passwd "$user" >/dev/null 2>&1 || { printf 'ERROR: account not found: %s\n' "$user"; exit 1; }
        if faillock --user "$2" --reset; then
            printf 'Account %s: Lock cleared\n' "$user"
        else
            printf 'Account %s: Failed to clear lock\n' "$user"
            exit 1
        fi
        ;;
    *)
        usage
        exit 2
        ;;
esac
