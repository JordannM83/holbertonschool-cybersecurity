#!/bin/bash
set -u

printf '%s\n\n' '=== Package Security Audit ==='
if ! command -v dpkg-query >/dev/null 2>&1; then printf '%s\n' 'ERROR: dpkg-query is required.'; exit 1; fi
is_installed() { [[ "$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null || true)" == installed ]]; }
check_group() {
    local title=$1; shift; local found=0 package label
    printf '%s\n' "$title"
    for entry in "$@"; do
        package=${entry%%|*}; label=${entry#*|}
        if is_installed "$package"; then printf '  [FOUND] %s (%s)\n' "$package" "$label"; found=$((found + 1)); fi
    done
    GROUP_COUNT=$found
}

check_group 'Checking for development tools...' 'gcc|GNU C Compiler' 'g++|GNU C++ Compiler' 'make|Build automation' 'gdb|Debugger'
dev_count=$GROUP_COUNT
printf '\n'
check_group 'Checking for network tools...' 'netcat-openbsd|Network Swiss Army Knife' 'nmap|Network scanner' 'tcpdump|Packet capture'
network_count=$GROUP_COUNT
printf '\n'
check_group 'Checking for remote access tools...' 'telnet|Insecure remote access'
remote_count=$GROUP_COUNT

printf '\n%s\n' 'Summary:'
printf '  Development tools: %s found\n' "$dev_count"
printf '  Network tools: %s found\n' "$network_count"
printf '  Remote access: %s found\n\n' "$remote_count"
printf '%s\n' 'Recommendation: Review and remove unnecessary packages.'
