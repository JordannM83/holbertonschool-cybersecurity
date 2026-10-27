#!/bin/bash

# Run the secure image with no Linux capabilities.
set -Eeuo pipefail

image=${1:-devstream-secure:dev}
container=devstream-secure

command -v docker >/dev/null 2>&1 || {
    printf '%s\n' 'ERROR: docker is required.'
    exit 1
}
docker image inspect "$image" >/dev/null 2>&1 || {
    printf 'ERROR: image not found: %s\n' "$image"
    exit 1
}

printf '%s\n' 'Dropping all capabilities...'
printf '%s\n' 'Adding back only required capabilities:'
printf '%s\n' '  (none needed for this application)'

printf '%s\n' 'Starting container...'
docker run -d \
    --name "$container" \
    --cap-drop=ALL \
    --security-opt=no-new-privileges:true \
    --read-only \
    --tmpfs /tmp:rw,noexec,nosuid,nodev \
    --pids-limit 256 \
    "$image" >/dev/null
printf '  Container: %s\n  Capabilities: NONE\n' "$container"

printf '%s\n' 'Verification:'
printf '%s\n' '  $ docker exec devstream-secure cat /proc/1/status | grep Cap'
cap_status=$(docker exec "$container" sh -c "grep '^Cap' /proc/1/status")
printf '%s\n' "$cap_status" | sed 's/^/  /'
if printf '%s\n' "$cap_status" | awk '$2 !~ /^0000000000000000$/ {bad=1} END {exit bad}'; then
    :
else
    printf '%s\n' 'Application status: FAILED (capabilities remain)'
    exit 1
fi

running=$(docker inspect --format '{{.State.Running}}' "$container")
if [[ "$running" == true ]]; then
    printf '%s\n' 'Application status: Running normally ✓'
else
    printf '%s\n' 'Application status: STOPPED'
    exit 1
fi

printf '%s\n' 'The container has ZERO elevated capabilities.'
printf '%s\n' "Even if compromised, the attacker's abilities are limited."
