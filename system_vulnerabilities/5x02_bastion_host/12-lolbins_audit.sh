#!/bin/bash
# Read-only audit of commonly abused Living off the Land binaries.
set -u

printf '%s\n\n' '=== Living off the Land Binaries Audit ==='
printf '%s\n\n' 'Checking GTFOBins candidates...'

check_group() {
    local title=$1; shift
    local entry path note mode
    printf '%s\n' "$title"
    for entry in "$@"; do
        path=${entry%%|*}; note=${entry#*|}
        if [[ -e "$path" ]]; then
            mode=$(stat -Lc '%A' "$path" 2>/dev/null || printf 'unknown')
            printf '  %s: %s (%s)\n' "$path" "$mode" "$note"
        else
            printf '  %s: NOT FOUND\n' "$path"
        fi
    done
    printf '\n'
}

check_group 'File Readers (can read sensitive files):' \
    '/usr/bin/cat|OK' \
    '/usr/bin/less|OK' \
    '/usr/bin/vim|WARNING: Can escape to shell'

check_group 'Shell Escapes:' \
    '/usr/bin/python3|WARNING: Can spawn shells' \
    '/usr/bin/perl|WARNING: Can spawn shells' \
    '/usr/bin/awk|OK'

check_group 'Network Tools:' \
    '/usr/bin/wget|WARNING: Can download payloads' \
    '/usr/bin/curl|WARNING: Can download payloads'

printf '%s\n' 'Note: These binaries are legitimate but should be monitored.'
printf '%s\n' 'See https://gtfobins.github.io/ for abuse techniques.'
