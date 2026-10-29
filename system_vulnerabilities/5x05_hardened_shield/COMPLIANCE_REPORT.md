# Hardened Shield Compliance Report

## 1. Executive Summary

Hardened Shield implements a documented security baseline for a containerized
Apache and OpenSSH service. The image uses a minimal Debian base, runs Apache
workers as the unprivileged shield account, generates SSH host keys at startup,
and contains no application secrets.

Runtime controls include dropped Linux capabilities, no-new-privileges,
seccomp, a read-only root filesystem, protected tmpfs mounts, resource limits,
health monitoring, and restricted ports. Kernel, filesystem, identity, service,
and container checks are automated by the Python audit tool.

## 2. Scope

This report covers the following project directory and deployment artifacts:

- Dockerfile and image build configuration
- Docker Compose runtime configuration
- Apache and OpenSSH startup behavior
- Kernel and filesystem hardening scripts
- PAM, password, SSH, and root-access controls
- SUID/SGID audit output
- Python security audit and generated Markdown report

The report covers the container baseline and its documented Docker runtime
profile. It does not certify the host operating system, Docker daemon,
external network controls, image registry, or application-specific code.

## 3. Controls Implemented

### Build and image controls

- Debian bookworm slim is used instead of a broad rolling image.
- Apache, OpenSSH, curl, procps, and tini are installed without recommended
  packages or retained APT lists.
- OCI labels identify the image purpose, owner, version, and source.
- Scripts are copied into the image and made executable.
- No passwords, private keys, tokens, or database credentials are embedded.

### Kernel and filesystem controls

- IP forwarding, ICMP redirects, source routing, and unsafe routing behavior
  are disabled through `/etc/sysctl.d/99-hardened-shield.conf`.
- Reverse-path filtering and SYN cookies are enabled.
- `/tmp`, `/var/tmp`, and `/dev/shm` are configured for noexec, nosuid, and
  nodev operation.
- SUID/SGID files are inventoried in the hardened-shield audit log.

### Identity and access controls

- PAM password complexity, history, and faillock settings are configured.
- Password aging defaults are set to 90 days maximum, 1 day minimum, and a
  14-day warning period.
- SSH password authentication and root login are disabled.
- Public-key authentication is enabled and SSH attempts are limited.
- The root account is locked and a legal SSH banner is configured.

### Container runtime controls

- All Linux capabilities are dropped.
- no-new-privileges and the default seccomp profile are enabled.
- The root filesystem is read-only.
- Only required runtime directories are writable through restricted tmpfs or
  named volumes.
- Memory is limited to 256 MB, swap is disabled, CPU to 0.5 cores, and PIDs to
  50.
- Only TCP ports 80 and 22 are published.
- An HTTP HEALTHCHECK runs every 30 seconds with a five-second timeout.

## 4. Test Results

The following validations were completed during implementation:

| Test | Result |
|---|---|
| Shell syntax for initialization scripts | PASS |
| Python compilation for audit tools | PASS |
| Dockerfile static control review | PASS |
| Compose security settings review | PASS |
| Audit report generation | PASS |
| Audit tool current environment score | 42% / FAIL |

The 42 percent audit score reflects the development host used for validation;
its kernel, filesystem, identity, and Apache/SSH runtime state did not have the
Hardened Shield baseline active. A final deployment test must run the audit
inside the built container after Docker is available and the initialization
controls have been applied.

Release acceptance requires an audit score of at least 80 percent and no open
critical identity, privilege, secret, or filesystem finding.

## 5. Residual Risks

- The Docker daemon and host kernel remain trusted dependencies outside the
  container boundary.
- Publishing SSH requires external key lifecycle management, network filtering,
  and monitoring.
- The default seccomp profile is not a custom least-syscall profile.
- Image vulnerability scanning, signing, and registry admission controls must
  be supplied by CI/CD and the registry platform.
- Apache and OpenSSH still increase attack surface compared with a single
  process container.
- Resource limits reduce denial-of-service impact but do not replace host-level
  capacity monitoring.
- Any temporary exception must have an owner, compensating control, expiry date,
  and security approval.

## 6. Sign-off

| Approval item | Owner | Status |
|---|---|---|
| Image build and dependency review | Platform Engineering | Pending |
| Runtime security profile review | Security Engineering | Pending |
| Vulnerability and secret scan | CI/CD Owner | Pending |
| Final container audit at 80% or higher | Security Engineering | Pending |
| SSH access and key ownership review | Operations | Pending |
| Residual-risk acceptance | CISO | Pending |
| Production deployment authorization | Change Advisory Board | Pending |

Deployment is not approved until all pending items are completed and the final
image digest, audit report, scan artifacts, and exception register are attached
to the change record.
