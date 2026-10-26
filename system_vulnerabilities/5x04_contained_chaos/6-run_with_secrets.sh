#!/bin/bash
# Build and run without placing database credentials in the image.
set -Eeuo pipefail

image=devstream-nosecrets:v1
: "${DB_HOST:?Set DB_HOST before running this script}"
: "${DB_USER:?Set DB_USER before running this script}"
: "${DB_PASSWORD:?Set DB_PASSWORD before running this script}"

command -v docker >/dev/null 2>&1 || { printf '%s\n' 'ERROR: docker is required.'; exit 1; }
printf '%s\n' 'Building image without embedded secrets...'
docker build -t "$image" -f Dockerfile .
printf '%s\n' 'Running with secrets supplied at runtime...'
# Equivalent usage: docker run -e DB_HOST=myhost -e DB_USER=myuser -e DB_PASSWORD=mypass devstream-nosecrets:v1.
docker run --rm \
    -e "DB_HOST=$DB_HOST" \
    -e "DB_USER=$DB_USER" \
    -e "DB_PASSWORD=$DB_PASSWORD" \
    "$image"
