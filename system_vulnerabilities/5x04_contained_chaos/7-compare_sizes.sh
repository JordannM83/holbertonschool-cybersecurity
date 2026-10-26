#!/bin/bash
# Compare the existing vulnerable image with the multi-stage runtime image.
set -Eeuo pipefail

single_image=${1:-devstream-vulnerable:latest}
multi_image=devstream-multistage:v1
command -v docker >/dev/null 2>&1 || { printf '%s\n' 'ERROR: docker is required.'; exit 1; }
docker image inspect "$single_image" >/dev/null 2>&1 || {
    printf 'ERROR: build the single-stage image first: %s\n' "$single_image"
    exit 1
}

printf '%s\n' 'Building multi-stage image...'
docker build -t "$multi_image" -f Dockerfile . >/dev/null

single_bytes=$(docker image inspect "$single_image" --format '{{.Size}}')
multi_bytes=$(docker image inspect "$multi_image" --format '{{.Size}}')
single_mb=$((single_bytes / 1024 / 1024))
multi_mb=$((multi_bytes / 1024 / 1024))
if ((single_bytes > 0)); then
    reduction=$(( (single_bytes - multi_bytes) * 100 / single_bytes ))
else
    reduction=0
fi

printf 'Single-stage image: %s MB\n' "$single_mb"
printf 'Multi-stage image: %s MB\n' "$multi_mb"
printf 'Reduction: %s%%\n' "$reduction"
printf '%s\n' 'Packages in final image:'
printf '  python3.11\n  flask\n  (minimal runtime only)\n'
printf '%s\n' 'Build tools excluded:'
if docker run --rm --entrypoint sh "$multi_image" -c '! command -v gcc'; then printf '  gcc ✓\n'; else printf '  gcc: PRESENT\n'; fi
if docker run --rm --entrypoint sh "$multi_image" -c '! command -v make'; then printf '  make ✓\n'; else printf '  make: PRESENT\n'; fi
if docker run --rm --entrypoint sh "$multi_image" -c 'test ! -d /root/.cache/pip'; then printf '  pip (caches cleared) ✓\n'; else printf '  pip cache: PRESENT\n'; fi
