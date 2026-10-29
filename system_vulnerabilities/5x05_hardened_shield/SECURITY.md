# Hardened Shield Security Architecture

## 1. Architecture Overview

Hardened Shield is a small Debian-based container that provides two services:

- Apache serves the web application on TCP port 80.
- OpenSSH provides restricted administration on TCP port 22.

The container starts through tini and the init-services script. SSH host keys
are generated at startup rather than baked into the image. Apache workers run
as the unprivileged shield account with UID 1000. The container image contains
no application credentials or private deployment secrets.

Docker Compose supplies the runtime security profile, resource limits, read-only
filesystem, temporary writable filesystems, configuration mounts, and log
volume. The container is intended to be replaced through image deployment,
not modified interactively.

## 2. Security Controls

### Image and build

- Debian bookworm slim minimizes the installed operating system.
- Only Apache, OpenSSH, curl, procps, tini, and required dependencies are
  installed.
- Image labels identify ownership, purpose, version, and source.
- Initialization scripts are copied into the image and made executable.
- No passwords, API keys, SSH private keys, or database credentials are stored
  in the Dockerfile or image layers.

### Runtime

- All Linux capabilities are dropped with cap_drop ALL.
- no-new-privileges and the default seccomp profile are enabled.
- The root filesystem is read-only.
- `/tmp`, Apache runtime directories, and SSH runtime directories use narrowly
  scoped tmpfs mounts with noexec, nosuid, and nodev.
- Memory, swap, CPU, and PID limits prevent resource exhaustion.
- Only TCP ports 80 and 22 are published.
- The service restarts automatically and has an HTTP health check.

### Kernel and filesystem

init-hardening.sh persists restrictive sysctl values for forwarding, ICMP
redirects, source routing, reverse-path filtering, SYN cookies, and spoofing
defense. It records SUID/SGID binaries and configures protected temporary
filesystem mounts.

### Identity and access

init-identity.sh configures password quality, password history, faillock, SSH
key-only access, password aging, and root account locking. The SSH banner and
authentication settings are validated before completion.

## 3. Usage Instructions

Build and start the stack from this directory:

    docker compose build
    docker compose up -d

Check service and health state:

    docker compose ps
    curl -fsS http://127.0.0.1/

SSH administration requires a previously provisioned key for the shield user:

    ssh -p 22 shield@HOST

Do not use docker exec to install packages or alter the running container.
Update the Dockerfile or configuration, rebuild the image, and redeploy it.

Stop the stack with:

    docker compose down

## 4. Audit Procedures

Run the Python audit tool from the project root:

    python3 scripts/audit.py

It checks kernel values, filesystem mount options, PAM and SSH configuration,
Apache/SSH processes, HTTP health, capabilities, seccomp, no-new-privileges,
and root filesystem mode. Results are written to audit_result.md. The command
returns zero at an overall score of at least 80 percent and returns one when
the score is below that threshold.

After every image rebuild or Compose change, record:

1. Image digest and build date
2. Audit result and failed controls
3. Docker image vulnerability and secret-scan results
4. Running container configuration and health state
5. Open ports and unexpected processes

Critical identity, privilege, secret, or filesystem findings block deployment.

## 5. Maintenance Guidelines

- Rebuild at least monthly and immediately after critical base-image advisories.
- Pin production base images by digest after review.
- Rotate SSH host keys and user credentials according to the operations policy.
- Review SUID/SGID audit output after package changes.
- Keep the Docker Bench Security and Python audit reports as release artifacts.
- Review resource limits and exposed ports at each service change.
- Keep SSH keys in an approved access-management system and remove departed
  users promptly.
- Never add a secret to an image, Dockerfile, build argument, or log.
- Record exceptions with an owner, compensating controls, expiry date, and
  security approval.
- Treat the container as immutable; repair by rebuilding and redeploying.
