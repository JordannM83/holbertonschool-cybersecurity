# DevStream Insecure Dockerfile Analysis

## Executive summary

This Dockerfile is unsuitable for production. It embeds credentials, builds
from a moving and unverified base image, installs a broad set of unnecessary
tools, runs the application as root, and does not establish a reproducible or
auditable software supply chain. A compromise of the application could
therefore become a container-root compromise, expose production database
credentials, and provide tools useful for lateral movement.

## Findings

### 1. Mutable `ubuntu:latest` base image

**Problem:** The image uses `ubuntu:latest` rather than a pinned release and
immutable digest.

**Why dangerous:** A rebuild can silently select a different OS release or
package set. The build is not reproducible, and a compromised or malicious
registry response could introduce vulnerable software.

**Exploitation:** An attacker who compromises the image supply chain or a
registry account can cause future builds to use a backdoored image. A newly
introduced vulnerability can also reach production without a reviewed code
change.

### 2. No image provenance or signature verification

**Problem:** The base image is pulled without a digest, signature policy, or
provenance verification.

**Why dangerous:** The build trusts an external artifact based only on its
name and mutable tag.

**Exploitation:** A registry compromise, tag replacement, or dependency-cache
poisoning can supply an image containing a privileged backdoor that runs when
the container starts.

### 3. Excessive packages and attack surface

**Problem:** The image installs `vim`, `net-tools`, `iputils-ping`, `curl`,
`wget`, `gcc`, `make`, and `sudo`, even though the container only runs a
Python application.

**Why dangerous:** Every extra binary and library adds vulnerabilities,
debugging capability, and maintenance burden. Compilers and network tools are
especially useful after an intrusion.

**Exploitation:** After exploiting the application, an attacker can use
`curl`/`wget` to download payloads, network utilities to map reachable
services, and `gcc`/`make` to compile a local exploit or malware.

### 4. Root password hard-coded into the image build

**Problem:** `RUN echo 'root:devstream123' | chpasswd` creates a predictable
root password in an image layer and attempts to enable password access.

**Why dangerous:** Docker image layers, build logs, CI caches, and registries
may retain the command or resulting filesystem data. The password is reused
by anyone who can inspect the Dockerfile or image.

**Exploitation:** An attacker who obtains the image or build output can recover
the password and use it for container access, SSH if installed later, or
credential-stuffing against other DevStream systems.

### 5. Production database credentials in `ENV`

**Problem:** `DB_USER` and `DB_PASSWORD` are embedded as Dockerfile environment
variables.

**Why dangerous:** Environment variables are visible through image metadata,
container inspection, process-environment reads, crash reports, and sometimes
application diagnostics. They also become part of the image's deployment
configuration.

**Exploitation:** An attacker with image-registry access, container access, or
an application information-disclosure bug can retrieve the credentials and
connect directly to the production database. The credentials should be
revoked because they have already been exposed in source material.

### 6. Application runs as root

**Problem:** No `USER` instruction is present, so the Python process runs as
root by default.

**Why dangerous:** A Python vulnerability, unsafe file operation, template
injection, or command injection immediately becomes root inside the container.
Root in the container also increases the chance of abusing container runtime
misconfigurations or mounted host resources.

**Exploitation:** An attacker first exploits the web application, then writes
or replaces files, installs tools, changes application behavior, and searches
for secrets with root privileges. If the container has excessive capabilities
or sensitive mounts, the compromise may extend toward the host.

### 7. `sudo` is installed unnecessarily

**Problem:** The image installs `sudo` while the service is already root and
does not define a controlled administrative workflow.

**Why dangerous:** It adds privileged code and encourages privilege-management
patterns that are inappropriate inside a minimal service container.

**Exploitation:** If a local user or compromised process is later introduced,
misconfigured sudo rules or a sudo vulnerability can provide another path to
root. An attacker can also use it to disguise privileged actions.

### 8. Unpinned Python dependencies

**Problem:** `pip3 install -r requirements.txt` does not show pinned versions,
hashes, a lock file, or a trusted package index.

**Why dangerous:** A rebuild may install a newer vulnerable package, a
typosquatted package, or a compromised dependency. The result is not
reproducible.

**Exploitation:** An attacker publishes a malicious package or takes over a
dependency release. The build installs it, and its setup or runtime code can
steal credentials, modify the application, or create a remote-access path.

### 9. Pip is run as root

**Problem:** Python packages are installed globally as root during the image
build.

**Why dangerous:** A malicious package's build hooks run with elevated build
privileges and can modify the image broadly. Global installation can also
overwrite system files or create conflicts.

**Exploitation:** A compromised dependency executes arbitrary code during
installation and plants a backdoor in the image or steals CI credentials.
Using a virtual environment and a non-root runtime limits the impact.

### 10. Entire build context copied into `/app`

**Problem:** `COPY . /app` copies everything in the build context, including
files that may be secrets, source-control metadata, local credentials, test
data, build artifacts, and private keys.

**Why dangerous:** The Dockerfile does not demonstrate a `.dockerignore`, so
the image may permanently contain sensitive files. It also expands the
application attack surface.

**Exploitation:** An attacker downloads an exposed application artifact or
triggers an information-disclosure endpoint, then searches `/app` for `.env`
files, cloud credentials, SSH keys, Git history, or configuration backups.

### 11. APT cache and package lists are left in the image

**Problem:** The installation layer does not remove `/var/lib/apt/lists` or
other package-manager caches.

**Why dangerous:** The image is larger and contains unnecessary package
metadata and potentially stale vulnerable artifacts. Larger images take
longer to scan and deploy.

**Exploitation:** An attacker can use retained package metadata to identify
software versions and select matching exploits. The size also increases the
chance that sensitive build material survives into production layers.

### 12. No security update or vulnerability-scanning policy

**Problem:** The Dockerfile has no explicit security update strategy, SBOM,
image scan, or build gate.

**Why dangerous:** Known vulnerabilities can remain in Ubuntu, Python, and
application dependencies unnoticed.

**Exploitation:** An attacker fingerprints the service, matches exposed
versions to a known CVE, and uses a public exploit against the application or
one of its libraries.

### 13. No health check or runtime hardening declaration

**Problem:** There is no `HEALTHCHECK`, read-only filesystem guidance, dropped
capability policy, seccomp/AppArmor profile, or resource limit documented in
the image.

**Why dangerous:** Orchestrators cannot reliably distinguish a healthy service
from a hung or compromised one, and deployments may run with excessive
runtime privileges.

**Exploitation:** A compromised process can consume CPU or memory, write
persistent files, or abuse capabilities that the deployment platform leaves
enabled. Monitoring may fail to restart or isolate the unhealthy container.

### 14. Port exposure is not restricted by the Dockerfile

**Problem:** `EXPOSE 5000` documents the application port but does not enforce
authentication, TLS, source-network restrictions, or a reverse-proxy policy.

**Why dangerous:** Operators may publish the development application port
directly to an untrusted network. The Python process is started without an
explicit production WSGI server or secure proxy configuration.

**Exploitation:** An attacker scans the host, reaches the application directly,
and exploits debug endpoints, weak application authentication, or unencrypted
traffic. `EXPOSE` itself is metadata, but unsafe deployment of that port is a
common consequence.

### 15. No explicit production Python runtime configuration

**Problem:** `CMD ["python3", "app.py"]` provides no indication that a
production-grade WSGI server, debug setting, logging policy, or TLS termination
is configured.

**Why dangerous:** Development defaults may expose tracebacks, unsafe reload
behavior, weak concurrency handling, or sensitive diagnostic information.

**Exploitation:** An attacker requests an error path and receives a traceback
containing source code, environment variables, filesystem paths, or database
credentials, then uses that information to compromise the application or
database.

## Priority remediation

1. Revoke and rotate the exposed database and root credentials immediately.
2. Replace the base image with a pinned, verified minimal image.
3. Remove compilers, `sudo`, editors, and network troubleshooting tools.
4. Use BuildKit or an orchestrator secret mechanism instead of `ENV` secrets.
5. Pin and hash Python dependencies, generate an SBOM, and scan build output.
6. Add a non-root user, drop capabilities, use a read-only root filesystem,
   and apply resource/security profiles at runtime.
7. Add a strict `.dockerignore`, health check, production WSGI server, and
   controlled network/TLS deployment.
