#!/bin/bash
# Build and inspect the intentionally vulnerable DevStream image.
set -Eeuo pipefail

image=devstream-vulnerable:latest
printf '%s\n' 'Creating application files...'

cat > app.py <<'PYTHON'
from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return f"Hello from DevStream! DB: {os.environ.get('DB_HOST', 'unknown')}"

@app.route('/health')
def health():
    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYTHON
printf '%s\n' '  app.py: Created'

cat > requirements.txt <<'REQUIREMENTS'
flask==3.0.0
REQUIREMENTS
printf '%s\n' '  requirements.txt: Created'

cat > Dockerfile <<'DOCKERFILE'
# DevStream's intentionally vulnerable production Dockerfile.
FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    wget \
    vim \
    net-tools \
    iputils-ping \
    gcc \
    make \
    sudo

RUN echo 'root:devstream123' | chpasswd

ENV DB_HOST=prod-db.devstream.internal
ENV DB_USER=admin
ENV DB_PASSWORD=Sup3rS3cr3t!Pr0d

WORKDIR /app
COPY . /app
RUN pip3 install -r requirements.txt

EXPOSE 5000
CMD ["python3", "app.py"]
DOCKERFILE
printf '%s\n' '  Dockerfile: Created'

command -v docker >/dev/null 2>&1 || { printf '%s\n' 'ERROR: docker is required.'; exit 1; }
printf '%s\n' 'Building image...'
docker build -t "$image" .
printf '  Image: %s\n  Build: SUCCESS\n' "$image"

size_bytes=$(docker image inspect "$image" --format '{{.Size}}')
if command -v numfmt >/dev/null 2>&1; then
    size=$(numfmt --to=iec --suffix=B "$size_bytes")
else
    size="${size_bytes} bytes"
fi
user=$(docker image inspect "$image" --format '{{.Config.User}}')
[[ -n "$user" ]] || user=root
user_id=$(docker run --rm --entrypoint id "$image" -u)
env_values=$(docker image inspect "$image" --format '{{range .Config.Env}}{{println .}}{{end}}')

printf '%s\n' 'Image Analysis:'
printf '  Size: %s\n' "$size"
printf '  Base: ubuntu:latest\n'
printf '  User: %s (UID %s)\n' "$user" "$user_id"
printf '%s\n' 'Environment Variables (EXPOSED SECRETS):'
printf '%s\n' "$env_values" | grep -E '^DB_(HOST|USER|PASSWORD)=' | sed 's/^/  /'
printf '%s\n' 'WARNING: This image contains hardcoded credentials!'
