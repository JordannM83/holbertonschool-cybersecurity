#!/bin/bash
# Demonstrate that Dockerfile secrets remain visible in image metadata/layers.
set -u

if [ $# -ne 1 ]; then
    printf 'Usage: %s IMAGE\n' "$(basename "$0")"
    exit 2
fi
command -v docker >/dev/null 2>&1 || { printf '%s\n' 'ERROR: docker is required.'; exit 1; }
image=$1
docker image inspect "$image" >/dev/null 2>&1 || { printf 'ERROR: image not found: %s\n' "$image"; exit 1; }

printf 'Image: %s\n' "$image"
printf '%s\n' 'Layer History:'
history=$(docker history --no-trunc --format '{{.CreatedBy}}' "$image")
layer=1
while IFS= read -r command; do
    [[ -n "$command" ]] || continue
    marker=''
    [[ "$command" == *'root:devstream123'* ]] && marker='  <- PASSWORD EXPOSED'
    [[ "$command" == *'DB_PASSWORD=Sup3rS3cr3t!Pr0d'* ]] && marker='  <- SECRET EXPOSED'
    printf '  Layer %d: %s%s\n' "$layer" "$command" "$marker"
    layer=$((layer + 1))
done <<< "$history"

printf '%s\n' 'Extracting secrets from history...'
root_password=$(printf '%s\n' "$history" | sed -n "s/.*root:\([^'[:space:]]*\).*/\1/p" | head -n1)
env_values=$(docker image inspect "$image" --format '{{range .Config.Env}}{{println .}}{{end}}')
db_password=$(printf '%s\n' "$env_values" | sed -n 's/^DB_PASSWORD=//p' | head -n1)
printf '  Root password: %s\n' "${root_password:-not found}"
printf '  DB Password: %s\n' "${db_password:-not found}"
printf '%s\n' 'CRITICAL: All ENV and RUN commands are permanently'
printf '%s\n' 'visible in image layers. Never put secrets here!'
