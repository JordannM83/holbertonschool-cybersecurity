# DevStream Container Security Guidelines

## 1. Dockerfile Rules

### Required

- Use a minimal, approved base image and pin it to a reviewed digest where
  practical.
- Use multi-stage builds so compilers, package managers, caches, and debugging
  tools do not reach production images.
- Create a dedicated non-root user and declare it with USER.
- Set a working directory and copy only the files required by the application.
- Pin application dependencies and install them without retaining package
  caches.
- Add a HEALTHCHECK that tests a meaningful application health endpoint.
- Add OCI labels for ownership, version, source repository, and build date.
- Review the final image contents and scan it before release.

### Prohibited

- Do not use latest for production deployments.
- Do not run the application as root.
- Do not embed passwords, tokens, private keys, or connection strings in
  Dockerfiles, build arguments, ENV instructions, source code, or image
  layers.
- Do not use ADD when COPY is sufficient.
- Do not install compilers, shells, editors, network scanners, or debugging
  tools in production images.
- Do not use privileged mode or add capabilities without an approved
  exception.
- Do not copy the entire repository blindly; use a reviewed build context and
  an appropriate .dockerignore file.

## 2. Base Image Policy

Approved defaults are official Python slim images for Python services, such as
Python 3.11 slim, and other vendor-maintained minimal images approved by the
platform team. Images must come from trusted registries and have a documented
support lifecycle.

The owning team must rebuild images at least monthly and whenever a critical
base-image vulnerability is announced. Critical or actively exploited
vulnerabilities require an expedited rebuild and deployment decision. CI must
scan the base image and fail releases for critical findings unless a signed
exception exists.

Image tags, digest, scan result, owner, and release date must be recorded in
the deployment manifest.

## 3. Secret Management

Secrets are supplied at deployment time through the approved secret manager,
or as short-lived runtime environment variables when the platform permits.
Container orchestrator secrets should preferably be mounted as files with
least-privilege permissions.

Developers must not commit secrets, place them in ENV or ARG instructions,
print them in logs, or pass them through image build commands. Local
development uses a developer-specific secret store or an ignored local
configuration file; no production credential may be reused for development.

Rotate credentials after accidental exposure, image publication, staff
changes, or suspected compromise. A secret found in an image is considered
compromised even if the corresponding Dockerfile line is later removed.

## 4. Runtime Requirements

Production containers must use:

- A non-root UID with no unnecessary supplementary groups
- Read-only root filesystem
- Writable tmpfs or volumes only for documented application paths
- no-new-privileges
- The default seccomp profile or a stricter approved profile
- All Linux capabilities dropped; add only a specifically justified capability
- CPU, memory, swap, and PID limits
- No privileged mode and no host network, PID, IPC, or Docker socket access
- A health check and an explicit restart policy managed by the platform
- Minimal network exposure and only required ports
- Resource and security labels identifying the owner and service

Production images must be immutable. Debugging or administrative access is
performed through approved, audited tooling rather than installing utilities
into a running container.

## 5. Audit Requirements

Every image must pass automated vulnerability scanning, secret scanning, and
Docker Bench Security checks before release. CI records the image digest and
the complete scan reports as release artifacts.

Teams must review running containers after every deployment and at least
monthly. The review checks image provenance, user identity, capabilities,
seccomp, no-new-privileges, filesystem mode, mounts, resource limits, exposed
ports, health state, and unexpected processes.

Security findings are tracked to closure. Critical findings block deployment;
high findings require a documented risk decision and remediation owner.
Material changes to the Dockerfile, base image, dependencies, or runtime
profile trigger a new audit.

## 6. Exception Process

An exception request must be submitted before deployment and include:

1. The exact service, image digest, and control being waived
2. Business and technical justification
3. Threat analysis and compensating controls
4. Scope, owner, start date, and expiration date
5. A remediation plan with a target date

The service owner and security team must approve the request. High-risk
exceptions additionally require CISO approval. Exceptions are time-limited,
reviewed at least every 30 days, and removed when the underlying dependency or
design constraint is resolved.

Emergency exceptions may be granted for an incident response window, but must
be documented within one business day and reviewed retrospectively. No
exception permits embedding secrets in an image or publishing a credential
that has not been rotated.
