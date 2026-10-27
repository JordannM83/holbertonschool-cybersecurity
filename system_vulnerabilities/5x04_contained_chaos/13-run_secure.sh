#!/bin/bash

# Run the application with Docker's recommended runtime security controls.
set -Eeuo pipefail

image=${1:-devstream-secure:dev}
container=devstream-secure-max

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

printf '%s\n' 'Security options applied:'
printf '%s\n' '  --security-opt=no-new-privileges:true'
printf '%s\n' '    (Process cannot gain new privileges via setuid, etc.)'
printf '%s\n' '  --security-opt=seccomp=default'
printf '%s\n' '    (Syscall filtering enabled)'
printf '%s\n' 'Additional hardening:'
printf '%s\n' '  --cap-drop=ALL'
printf '%s\n' '  --read-only'
printf '%s\n' '  --user=appuser'

docker run -d +    --name "$container" +    --security-opt=no-new-privileges:true +    --security-opt=seccomp=default +    --cap-drop=ALL +    --read-only +    --tmpfs /tmp:rw,noexec,nosuid,nodev +    --user=appuser +    "$image" >/dev/null
printf '%s\n' 'Container started with maximum hardening.'

printf '%s\n' 'Security verification:'
security_options=$(docker inspect --format '{{join .HostConfig.SecurityOpt " "}}' "$container")
user_id=$(docker exec "$container" id -u)
if [[ "$security_options" == *'no-new-privileges:true'* ]]; then
    printf '%s\n' '  New privileges: BLOCKED'
else
    printf '%s\n' '  New privileges: NOT BLOCKED'
    exit 1
fi
if [[ "$security_options" == *'seccomp=default'* ]]; then
    printf '%s\n' '  Seccomp: ENABLED'
else
    printf '%s\n' '  Seccomp: NOT ENABLED'
    exit 1
fi
if [[ "$user_id" != 0 ]]; then
    printf '%s\n' '  Root access: NONE'
else
    printf '%s\n' '  Root access: AVAILABLE'
    exit 1
fi
