Learning Objectives
This Capstone validates that you can:

Integrate multiple security domains into a cohesive solution

Apply hardening techniques without step-by-step guidance

Build production-ready containerized infrastructure

Automate security configuration and auditing

Document security controls for compliance purposes
# Hardened Shield

Hardened Shield is a security-focused Apache and OpenSSH container baseline for
NovaTech Solutions. It combines operating-system hardening, identity controls,
service validation, container runtime restrictions, and automated auditing.

The image uses Debian slim, runs Apache workers as the non-root `shield` user,
generates SSH host keys at startup, and does not contain application secrets.

## Quick Start

Build the image from this directory:

```sh
docker compose build
```

Start the service:

```sh
docker compose up -d
```

Verify the container and HTTP endpoint:

```sh
docker compose ps
curl -fsS http://127.0.0.1/
```

The service publishes Apache on port 80 and SSH on port 22. SSH access requires
an approved public key for the `shield` account:

```sh
ssh -p 22 shield@HOST
```

Stop the environment with:

```sh
docker compose down
```

## File Structure

```text
5x05_hardened_shield/
├── Dockerfile
├── docker-compose.yml
├── SECURITY.md
├── COMPLIANCE_REPORT.md
├── audit_result.md
├── audit.py
├── README.md
├── scripts/
│   ├── init-hardening.sh
│   ├── init-identity.sh
│   ├── init-services.sh
│   └── audit.py
└── config/
```

`audit.py` at the project root is a compatibility entry point. The primary
implementation is `scripts/audit.py`.

## Build and Run Instructions

Build without using stale layers when performing a release rebuild:

```sh
docker compose build --no-cache
docker compose up -d
```

Inspect health and logs:

```sh
docker inspect --format='{{.State.Health.Status}}' hardened-shield
docker compose logs --tail=100 shield
```

Run the security audit:

```sh
python3 scripts/audit.py
```

The audit prints formatted results and writes the formal Markdown report to
`audit_result.md`. It returns success at 80 percent or higher and failure below
that threshold.

Rebuild and redeploy after changing Dockerfile, scripts, or configuration. Do
not install packages or modify security settings interactively in a running
container.

## Security Features Summary

- Debian slim base image with a reduced package set
- Apache web server and OpenSSH service
- Apache workers running as non-root UID 1000
- SSH root login and password authentication disabled
- Password complexity, history, aging, and faillock configuration
- Kernel forwarding, redirect, source-routing, and spoofing protections
- SUID/SGID inventory generation
- Legal SSH access banner
- All Linux capabilities dropped
- `no-new-privileges` and default seccomp profile
- Read-only root filesystem
- Hardened tmpfs mounts using `noexec`, `nosuid`, and `nodev`
- Memory, swap, CPU, and PID limits
- HTTP health check with automatic restart policy
- Only ports 80 and 22 exposed
- No credentials or private keys embedded in the image
- Python audit covering kernel, filesystem, identity, services, and container
  controls

See [SECURITY.md](SECURITY.md) for the architecture and operational security
requirements, and [COMPLIANCE_REPORT.md](COMPLIANCE_REPORT.md) for formal
compliance evidence and residual risks.
