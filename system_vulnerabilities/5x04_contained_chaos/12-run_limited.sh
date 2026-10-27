#!/bin/bash

# Run the application with bounded host resource consumption.
set -Eeuo pipefail

image=${1:-devstream-secure:dev}
container=devstream-limited
memory_bytes=268435456
cpu_nano=500000000

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

printf '%s\n' 'Applying limits:'
printf '%s\n' '  --memory=256m (max 256MB RAM)'
printf '%s\n' '  --memory-swap=256m (no swap)'
printf '%s\n' '  --cpus=0.5 (max 50% of one CPU)'
printf '%s\n' '  --pids-limit=50 (max 50 processes)'

docker run -d +    --name "$container" +    --memory=256m +    --memory-swap=256m +    --cpus=0.5 +    --pids-limit=50 +    --cap-drop=ALL +    --security-opt=no-new-privileges:true +    "$image" >/dev/null
printf 'Container started: %s\n' "$container"

memory=$(docker inspect --format '{{.HostConfig.Memory}}' "$container")
memory_swap=$(docker inspect --format '{{.HostConfig.MemorySwap}}' "$container")
cpu_nano_actual=$(docker inspect --format '{{.HostConfig.NanoCpus}}' "$container")
pids_limit=$(docker inspect --format '{{.HostConfig.PidsLimit}}' "$container")

printf '%s\n' 'Verification:'
if [[ "$memory" == "$memory_bytes" && "$memory_swap" == "$memory_bytes" ]]; then
    printf '%s\n' '  Memory limit: 256MB'
else
    printf '  Memory limit: FAILED (memory=%s swap=%s)\n' "$memory" "$memory_swap"
    exit 1
fi
if [[ "$cpu_nano_actual" == "$cpu_nano" ]]; then
    printf '%s\n' '  CPU limit: 0.5 cores'
else
    printf '  CPU limit: FAILED (%s nano CPUs)\n' "$cpu_nano_actual"
    exit 1
fi
if [[ "$pids_limit" == 50 ]]; then
    printf '%s\n' '  PID limit: 50'
else
    printf '  PID limit: FAILED (%s)\n' "$pids_limit"
    exit 1
fi

printf '%s\n' 'Resource limits active.'
printf '%s\n' 'Container cannot exhaust host resources.'
