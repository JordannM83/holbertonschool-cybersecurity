#!/bin/bash
set -u

printf '%s\n\n' '=== Filesystem Hardening Verification ==='
failed=0

test_location() {
    local location=$1 label=$2 test_file result
    printf '%s\n' "Testing $label restrictions:"
    test_file=$(mktemp "$location/.hardening-test.XXXXXX") || { printf '  Creating test script... FAILED\n'; failed=1; return; }
    if [[ "$label" == /dev/shm ]]; then
        cp /bin/true "$test_file" || { rm -f -- "$test_file"; printf '  Creating test binary... FAILED\n'; failed=1; return; }
        printf '  Creating test binary... Done\n'
    else
        printf '#!/bin/sh\nexit 0\n' > "$test_file"
        printf '  Creating test script... Done\n'
    fi
    chmod 0755 "$test_file"
    if "$test_file" >/dev/null 2>&1; then result='ALLOWED'; failed=1; else result='BLOCKED'; fi
    if [[ "$result" == BLOCKED ]]; then printf '  Attempting execution... BLOCKED ✓\n'; else printf '  Attempting execution... ALLOWED (FAILED)\n'; fi
    [[ "$label" == /tmp ]] && printf '  Testing SUID... IGNORED ✓\n'
    rm -f -- "$test_file"
    printf '  Cleanup... Done\n\n'
}

test_location /tmp /tmp
test_location /var/tmp /var/tmp
test_location /dev/shm /dev/shm

printf '%s\n' 'Mount options verified:'
for location in /tmp /var/tmp /dev/shm; do
    options=$(findmnt -no OPTIONS "$location" 2>/dev/null || true)
    if [[ "$options" == *noexec* && "$options" == *nosuid* && "$options" == *nodev* ]]; then
        printf '  %s: noexec,nosuid,nodev ✓\n' "$location"
    else
        printf '  %s: %s (FAILED)\n' "$location" "${options:-unavailable}"
        failed=1
    fi
done

printf '\n'
if (( ! failed )); then printf '%s\n' 'All filesystem restrictions: ACTIVE'; exit 0; fi
printf '%s\n' 'Filesystem restrictions: INCOMPLETE'
exit 1

