#!/bin/bash

# Run the application with an immutable root filesystem and narrow write areas.
set -Eeuo pipefail

image=${1:-devstream-secure:dev}
container=devstream-readonly

command -v docker >/dev/null 2>&1 || {
    printf '%s\n' 'ERROR: docker is required.'
    exit 1
}
docker image inspect "$image" >/dev/null 2>&1 || {
    printf 'ERROR: image not found: %s\n' "$image"
    exit 1
}
if docker container inspect "$container" >/dev/null 2>&1; then
    printf 'ERROR: container already exists: %s\n' "$container"
    exit 1
fi

printf '%s\n' 'Starting container with:'
printf '%s\n' '  --read-only'
printf '%s\n' '  --tmpfs /tmp (for temporary files)'
printf '%s\n' '  --tmpfs /app/logs (for application logs)'
docker run -d +    --name "$container" +    --read-only +    --tmpfs /tmp:rw,noexec,nosuid,nodev +    --tmpfs /app/logs:rw,noexec,nosuid,nodev +    --cap-drop=ALL +    --security-opt=no-new-privileges:true +    "$image" >/dev/null

printf '%s\n' 'Verification:'
check_write() {
    local path=$1 expected=$2 label=$3
    if docker exec "$container" sh -c "printf test > '$path'" >/dev/null 2>&1; then
        actual=ALLOWED
    else
        actual=BLOCKED
    fi
    if [[ "$actual" == "$expected" ]]; then
        printf '  Attempt to write to %s: %s\n' "$path" "$actual"
    else
        printf '  Attempt to write to %s: %s (unexpected)\n' "$path" "$actual"
        printf 'ERROR: %s verification failed.\n' "$label"
        exit 1
    fi
}

check_write /etc/devstream-readonly-test BLOCKED 'read-only /etc'
check_write /app/devstream-readonly-test BLOCKED 'read-only /app'
check_write /tmp/devstream-readonly-test ALLOWED 'writable /tmp'
check_write /app/logs/devstream-readonly-test ALLOWED 'writable application logs'

if docker exec "$container" sh -c +    "printf 'health-check\n' > /app/logs/application.log && test -s /app/logs/application.log"; then
    printf '%s\n' '  Application logging: WORKING'
else
    printf '%s\n' '  Application logging: FAILED'
    exit 1
fi

readonly_root=$(docker inspect --format '{{.HostConfig.ReadonlyRootfs}}' "$container")
if [[ "$readonly_root" == true ]]; then
    printf '%s\n' 'Root filesystem: READ-ONLY'
else
    printf '%s\n' 'Root filesystem: READ-WRITE (unexpected)'
    exit 1
fi

printf '%s\n' 'Attackers cannot modify system files or drop tools.'
