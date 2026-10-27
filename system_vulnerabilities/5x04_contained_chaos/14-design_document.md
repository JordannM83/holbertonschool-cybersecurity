# Secure Python Development Environment

## 1. Base Image Selection

The environment uses `python:3.11-slim` as its runtime base. The slim variant
provides the supported Python runtime while avoiding the compilers, editors,
debuggers, and package inventory found in a general-purpose distribution image.
The image should be pinned to a reviewed digest in CI and rebuilt regularly for
security updates.

A multi-stage build keeps build-only dependencies out of the final image. The
runtime image contains only Python, the application, and its runtime
dependencies.

## 2. Included Development Tools

Development dependencies are installed into the builder or development image,
not into the production runtime image:

- `pytest` for automated tests
- `pytest-cov` for coverage reporting
- `pylint` for static analysis
- `black` for consistent formatting
- `ruff` for fast linting and import checks

Dependencies are pinned in a requirements file and installed with
`--no-cache-dir`. The production image receives only the application runtime
requirements, such as Flask.

## 3. User Configuration

The image creates `appuser` with a fixed UID/GID of `1000`, a home directory,
and a non-login shell. Application files are owned by `appuser`, and the image
declares `USER appuser`. No application process or development command runs as
root.

The container does not contain passwords, API keys, or database credentials.
Those values are supplied at runtime through an approved secret mechanism.

## 4. Volume Strategy

Source code is mounted into `/app` for development. The source mount is
restricted to the project directory and should be read-only when the command
does not need to edit files. A separate writable mount or tmpfs is used for
test artifacts and caches.

Recommended writable locations are:

- `/tmp` as a `noexec,nosuid,nodev` tmpfs
- `/app/logs` as a narrowly scoped writable tmpfs or named volume
- An optional isolated cache volume for package/test caches

The production container uses an immutable application layer rather than a
host source-code bind mount.

## 5. Security Measures

The runtime configuration applies the following controls:

- `--cap-drop=ALL`; no capabilities are added unless a documented requirement
  is approved.
- `--security-opt=no-new-privileges:true` to block privilege acquisition.
- The default seccomp profile for syscall filtering.
- `--read-only` for the container root filesystem.
- `noexec,nosuid,nodev` on temporary writable filesystems.
- Memory, CPU, and PID limits to prevent resource exhaustion.
- A non-root `appuser` and a non-login shell.
- No hardcoded secrets in Dockerfiles, image layers, or `ENV` declarations.
- Health checks against `/health` every 30 seconds, with a 10-second timeout
  and three retries.
- Minimal network exposure; only the required application port is published.
- Dependency and base-image scanning in CI, with regular rebuilds and review.
- A narrowly scoped Compose configuration for local development.

The development Compose service should preserve these controls while allowing
interactive commands such as tests, linting, and formatting.

## 6. Developer Experience

Build the environment with:

```sh
docker build -t devstream-dev:latest -f Dockerfile .
```

Start an interactive shell or run common tools through Compose:

```sh
docker compose run --rm dev python my_script.py
docker compose run --rm dev pytest tests/
docker compose run --rm dev pylint my_module/
docker compose run --rm dev black --check .
```

Developers edit files on the host; the bind mount makes changes immediately
available inside the container. Tests and linters run with the same Python
version used by CI, reducing “works on my machine” differences.

Database and other service credentials are provided only for the individual
command or through Compose secrets, for example:

```sh
DB_HOST=db.example.internal DB_USER=developer DB_PASSWORD='use-a-secret-store' \
  docker compose run --rm dev pytest tests/
```

Never commit credentials, copy `.env` files into the image, or print secrets in
logs. When a command needs additional privileges or writable storage, the
requirement must be documented and reviewed rather than weakening the default
container profile.
