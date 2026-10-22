#!/bin/bash
# View fail2ban status and manage SSH bans.
set -u

usage() {
    printf 'Usage: %s status | banned | unban IP\n' "$(basename "$0")"
}

if [ "$#" -eq 0 ]; then
    usage
    exit 2
fi
command -v fail2ban-client >/dev/null 2>&1 || {
    printf '%s\n' 'ERROR: fail2ban-client is not installed or not in PATH.'
    exit 1
}

if [ $1 == "status" ]; then
    action=status
fi
case "$1" in
    status)
        printf '%s\n\n' '=== fail2ban Status ==='
        if command -v systemctl >/dev/null 2>&1; then
            service_status=$(systemctl is-active fail2ban.service 2>/dev/null || true)
        else
            service_status=unknown
        fi
        printf 'Service: %s\n' "${service_status:-unknown}"
        jail_status=$(fail2ban-client status 2>/dev/null || true)
        jails=$(printf '%s\n' "$jail_status" | sed -n 's/.*Jail list:[[:space:]]*//p' | tr ',' '\n' | sed 's/^ *//;s/ *$//')
        printf 'Jails: %s\n' "${jails:-none}"
        printf '\n%s\n' '[sshd] Statistics:'
        ssh_status=$(fail2ban-client status sshd 2>/dev/null || true)
        if [[ -n "$ssh_status" ]]; then
            printf '%s\n' "$ssh_status" | sed -n -E \
                -e 's/^[[:space:]]*Currently banned:[[:space:]]*/  Currently banned: /p' \
                -e 's/^[[:space:]]*Total banned:[[:space:]]*/  Total banned: /p' \
                -e 's/^[[:space:]]*Currently failed:[[:space:]]*/  Currently failed: /p'
        else
            printf '%s\n' '  Jail sshd is not active.'
        fi
        ;;
    banned)
        printf '%s\n\n' '=== Banned IPs ==='
        printf '%s\n' 'Jail: sshd'
        banned_ips=$(fail2ban-client get sshd banip 2>/dev/null || true)
        if [[ -n "$banned_ips" ]]; then
            printf '%s\n' "$banned_ips" | sed 's/^/  /'
        else
            printf '%s\n' '  None'
        fi
        ;;
    unban)
        [[ -n "${2:-}" ]] || { usage; exit 2; }
        [[ ${EUID:-$(id -u)} -eq 0 ]] || { printf '%s\n' 'ERROR: unban requires root privileges.'; exit 1; }
        ip=$2
        # Equivalent fail2ban-client set sshd unbanip $2 command.
        if fail2ban-client set sshd unbanip "$ip" >/dev/null; then
            printf 'IP %s unbanned from jail sshd\n' "$ip"
        else
            printf 'Failed to unban IP %s from jail sshd\n' "$ip"
            exit 1
        fi
        ;;
    *)
        usage
        exit 2
        ;;
esac
