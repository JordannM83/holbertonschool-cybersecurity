# Nexus Financial Access Control Policy

**Owner:** CTO and Interim CISO
**Applies to:** Employees, contractors, service accounts, Linux hosts, cloud resources, databases, CI/CD, and administrative interfaces
**Objective:** Give developers a fast, attributable path to the systems they need while removing shared credentials and unnecessary privilege.

This policy implements least privilege, individual accountability, and defense in depth.
The `nexus_master.pem` key is not an efficiency control: it is an untraceable,
single-key failure. It must be revoked and replaced with per-person access through a
controlled path.

## 1. Authentication

Authentication proves **who** is requesting access. Authorization, described below,
determines what that identity may do.

### 1.1 Human identities

- Every employee and contractor receives one unique corporate identity. Accounts may not
  be shared, renamed between people, or reused after departure.
- The identity provider is the source of truth for employment status. Disable accounts and
  revoke sessions, VPN access, SSH keys, tokens, and badges at termination; target same-day
  revocation and immediate revocation for involuntary termination.
- Require phishing-resistant MFA (FIDO2/WebAuthn) for administrators and VPN/bastion access.
  TOTP is the approved fallback; SMS is not an approved factor for privileged access.
- Passwords must be unique to Nexus, managed by the approved password manager, and never
  stored in Slack, source code, shell history, tickets, or whiteboards. Enforce the identity
  provider's password screening and rate limiting rather than relying on a predictable PIN.
- Use a separate named administrator identity for privileged work. A user's normal account
  must not be a member of a blanket `sudo` or cloud-admin group.

### 1.2 SSH authentication

- The shared `nexus_master.pem` key is prohibited. Immediately inventory its copies, remove
  it from Slack and hosts, revoke its authorized-key entries, and rotate any credentials it
  could access. Treat the private key as compromised even if no misuse is known.
- Each person generates an individual Ed25519 key locally (`ssh-keygen -t ed25519`) with a
  passphrase. Private keys stay on the managed endpoint or approved hardware token and are
  never emailed, uploaded, or copied to servers.
- Keys are registered to the person's identity and device, with owner, fingerprint, scope,
  creation date, and expiry. No key is authorized without manager/system-owner approval.
- Prefer short-lived SSH certificates issued by the bastion after successful SSO and MFA.
  If static keys are temporarily necessary, set an expiry/review date of no more than 90
  days and rotate them at review, role change, device loss, or suspected compromise.
- `/etc/ssh/authorized_keys` must contain only approved individual keys or a controlled
  `AuthorizedKeysCommand` result. Each entry must have a forced command, source restriction,
  or other scope where the workload permits. Never use a private key as a team password.
- Disable password SSH authentication and direct root login on managed Linux hosts:

  ```text
  PasswordAuthentication no
  KbdInteractiveAuthentication no
  PermitRootLogin no
  PubkeyAuthentication yes
  AllowGroups nexus-ssh
  ```

- Use `sudo` for approved privileged commands so the user's identity, command, time, and
  host are logged. Break-glass access is a named, vaulted, time-limited account requiring
  two-person approval and a post-use review; it is not a shared PEM file.

### 1.3 Service and machine identities

- Services, CI/CD jobs, backups, and database applications use separate non-human accounts.
  A service account may not be used for interactive login or shared with a developer.
- Store service credentials in a managed secrets vault. Retrieve them at runtime using a
  workload identity where supported; never commit them to Git or place them in Slack.
- Give each service its own credential and rotate it without taking unrelated services down.
  Disable and rotate credentials on ownership change or suspected exposure.

### 1.4 Authentication evidence

The identity provider, bastion, SSH daemon, `sudo`, VPN, and cloud control plane must log
successful and failed authentication, MFA result, source address, target, key fingerprint,
session start/end, and account changes. Send logs to centralized storage outside the host.

## 2. Authorization

Authorization is deny-by-default and is granted by role, resource, and action. Access is
approved by the resource owner, recorded in an access register, reviewed monthly for
privileged roles and quarterly for all other roles.

### 2.1 Linux RBAC model

Use groups for stable job functions and `sudoers` for command-level privilege. Do not grant
access by manually adding arbitrary users to `root`, `sudo`, or unrestricted application
groups.

| Group / role | Intended access | Prohibited by default |
|---|---|---|
| `nexus-ssh` | SSH to approved hosts through the bastion | Root login and direct Internet SSH |
| `nexus-developers` | Source code, development hosts, non-production logs | Production write, database administration, `sudo` |
| `nexus-ops` | Production deployment and approved operational commands | Unreviewed code changes and unrestricted database reads |
| `nexus-db-read` | Read-only production queries for approved diagnostics | `INSERT`, `UPDATE`, `DELETE`, DDL, exports |
| `nexus-security` | Audit logs, alerts, access reviews, incident evidence | Application or database modification |
| `nexus-breakglass` | Time-limited emergency access with approval | Permanent membership or routine use |
| Service-specific account | Only its required files, ports, API, or database role | Interactive shell and unrelated resources |

The implementation must enforce the following on Ubuntu hosts:

- Create groups with stable names, use an approved identity-to-group mapping, and record
  every membership change. A person may belong to multiple groups only when each grant is
  approved and reviewed.
- Set sensitive files and directories to least-privilege ownership and mode. Example:
  application code is owned by its deployment group, secrets are readable only by the
  owning service, and `/etc/shadow` remains root-owned and unreadable to ordinary users.
- Configure `/etc/sudoers.d/nexus-<role>` with `visudo`-validated, command-specific rules.
  Prefer `/usr/bin/systemctl restart <approved-service>`, deployment wrappers, and read-only
  diagnostics over unrestricted `/bin/bash`, editors, `sudo su`, or `sudo -i`.
- Log and alert on changes to `/etc/passwd`, `/etc/group`, `/etc/sudoers*`, SSH authorized
  keys, service units, firewall rules, and application deployment configuration.
- Use AppArmor profiles for network-facing services and protect service files, logs, and
  backup configuration from the service account that runs the application.

### 2.2 Production and database authorization

- Developers work in development/staging by default. Production access requires a ticket,
  approved purpose, named operator, time window, and automatic expiry.
- Production deployments go through reviewed CI/CD. The pipeline identity may deploy signed,
  approved artifacts; it may not provide an interactive root shell.
- PostgreSQL roles are separate for application runtime, migrations, read-only diagnostics,
  backup, and database administration. The application runtime role cannot create roles,
  alter schemas, or read unrelated databases.
- Grant database access to groups, not individual ad-hoc accounts. Use TLS, database audit
  logging, and row/table privileges where applicable. Exporting production data requires
  explicit approval and an encrypted, time-limited destination.
- The CEO, CTO, developers, and operations staff receive no implicit administrator access.
  Business authority does not bypass technical controls or logging.

### 2.3 Access review and emergency access

- Managers review direct reports; resource owners review permissions; the CISO samples the
  evidence. Remove unused access immediately rather than waiting for the review cycle.
- An emergency operator may activate break-glass access only for a declared incident or
  outage, with incident/ticket number and second-person approval where practicable.
  Automatically expire it, capture commands, and review the session within one business day.
- A failed access request is logged and must not be worked around with a shared account or
  copied private key.

## 3. Network access

Network controls enforce where a connection may originate and which service may be reached.
They supplement identity controls; a trusted identity is not a reason to expose a service
to the entire Internet.

### 3.1 Required zones and flows

| Source | Destination | Allowed path | Decision |
|---|---|---|---|
| Public Internet | Public web/API load balancer | HTTPS 443 through WAF/rate limiting | Allow only required application traffic |
| Public Internet | PostgreSQL, SSH, cloud management | None | Deny; no `0.0.0.0/0` rules |
| Developer device | Bastion/VPN | Required VPN or bastion endpoint with SSO + MFA | Allow and log |
| Bastion/VPN | Linux SSH | TCP 22 to approved hosts only | Allow by role and host group |
| Application service | PostgreSQL | Private network, TLS, application DB role, database port only | Allow narrowly |
| CI/CD runner | Deployment target | Private deployment channel and short-lived identity | Allow only approved artifacts/actions |
| Backup service | Database and backup bucket | Required backup endpoints and ports only | Allow scheduled job identity |
| Guest Wi-Fi | Corporate, management, server networks | None; Internet only | Deny and isolate |
| Corporate user network | Management interfaces | None unless explicitly approved | Deny by default |

### 3.2 Host and cloud implementation requirements

- Place production hosts and PostgreSQL in private subnets. Permit database traffic only from
  the application security group, migration runner, backup role, and approved bastion path.
- Configure cloud security groups and host firewall rules with explicit source, destination,
  protocol, and port. Default inbound policy is deny; outbound access is restricted where
  the service can operate without unrestricted egress.
- On Ubuntu, manage rules through the approved firewall automation (for example, UFW or
  nftables) and preserve them across reboot. SSH host rules must allow only the bastion/VPN
  network, never the public Internet.
- Segment guest, corporate, server, and management traffic using separate VLANs/security
  groups. Disable unused switch ports and require authenticated network access where the
  equipment supports 802.1X/NAC.
- Use administrative DNS and private service discovery for internal services. Do not publish
  database, SSH, monitoring, or management records in public DNS.
- Record firewall/security-group changes as code or an approved change ticket. Review rules
  monthly and remove temporary rules when their expiry is reached.

### 3.3 Developer workflow without the shared key

1. The developer signs in to the corporate identity provider with MFA from a managed laptop.
2. The developer connects to the VPN or bastion; the bastion issues a short-lived identity-
   bound SSH certificate after checking group membership and host scope.
3. The developer reaches only the development/staging host or specifically approved production
   target. Production changes use the deployment pipeline whenever possible.
4. The bastion, SSH daemon, `sudo`, deployment system, and database record the same user,
   ticket, target, and time window. The session expires when the approval expires.

This retains a rapid, repeatable on-call path while making every action attributable and
revocable. The temporary compatibility path, if required during migration, is a single
named key per user with a 90-day maximum expiry and no production-wide access; it must be
removed after bastion/certificate access is operational.

## 4. Implementation and compliance checks

The future automation must be idempotent and fail safely. At minimum, it must verify:

- `nexus_master.pem` is absent from Slack exports, host authorized-key files, repositories,
  CI variables, and backups, and its corresponding public key is revoked.
- `sshd` denies password and root login and permits only the approved SSH group/path.
- Required Linux groups, ownership, file modes, AppArmor profiles, and `sudoers` rules exist.
- PostgreSQL has no public security-group or firewall rule and accepts only approved private
  sources over TLS.
- MFA is required for identity-provider, VPN, bastion, cloud, and administrative access.
- Central logs show individual authentication, authorization, network-rule, and privileged
  command events.
- A disabled user, expired key, removed group membership, and expired network rule fail an
  access test within the required revocation window.

Exceptions require CISO approval, a named owner, documented business reason, compensating
control, and expiry date. Convenience, urgency, or seniority is not an exception reason.
