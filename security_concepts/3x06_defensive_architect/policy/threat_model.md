# Nexus Financial Threat Model

**Document owner:** Interim CISO
**Scope:** Nexus Financial office, cloud infrastructure, production application, data, personnel, and supporting processes
**Assessment date:** 2026-09-19
**Method:** STRIDE (Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege)

## 1. Purpose and risk context

Nexus is a FinTech startup preparing for an IPO. The five-day audit deadline makes the
following business objectives urgent:

1. Protect customer and financial data (confidentiality and privacy).
2. Keep the production service and database available.
3. Preserve trustworthy evidence for investigations and the external auditor.
4. Ensure only approved people and services can change production systems or data.

This model is based on the field notes supplied by management. It assumes the production
application and PostgreSQL database are hosted in the cloud, while engineers administer
them from company MacBooks and the co-working office. The model must be revisited when
the actual cloud account, data classification, and network diagram are confirmed.

## 2. Assets and trust boundaries

### High-value assets

- Customer, transaction, authentication, and production database records.
- Production application, infrastructure, and administrator interfaces.
- SSH private keys, database credentials, API tokens, and backup credentials.
- Source code, deployment pipelines, and build artifacts.
- S3 database backups and their encryption keys.
- Building access, laptops, network equipment, and audit logs.
- Availability and integrity of the service during the IPO audit.

### Trust boundaries

1. **Public Internet to application:** unauthenticated clients and attackers reach the public service.
2. **Internet to PostgreSQL:** currently an unsafe direct boundary because port 5432 is open to `0.0.0.0/0`.
3. **Remote engineers to production:** Bali and other remote staff cross a boundary without a reliable VPN control.
4. **Office/co-working space to Nexus systems:** visitors can currently enter and approach equipment.
5. **Developer endpoints to privileged systems:** shared Slack SSH key and excessive root access collapse this boundary.
6. **Production environment to backups/logging:** a local compromise must not allow an attacker to erase all evidence or backups.

## 3. STRIDE analysis

The table identifies the **single highest-priority threat** for each component. “Top threat”
is intentionally one item per component so that the five-day remediation plan remains
actionable; other STRIDE threats remain in scope for later treatment.

| Component / asset | STRIDE category | Top 1 threat | Most likely threat actor | Impact | Immediate control mapping |
|---|---|---|---|---|---|
| Co-working office entrance and visitor process | Spoofing | An unauthorized person enters while posing as a visitor, contractor, or employee because there is no working check-in or escort process. | Opportunistic intruder or targeted social engineer | High: physical access to laptops, credentials, and network equipment | Repair visitor check-in; require ID, host approval, visitor badge, escort, and visitor log. |
| Core/server room and racks | Tampering | An unescorted person changes, disconnects, or installs equipment in the rack; the biometric door is defeated by the propped-open door. | Opportunistic intruder or malicious delivery contractor | Critical: outage, interception, or persistent compromise | Keep the door closed; repair cooling; restrict named personnel; maintain access logs and CCTV; inspect rack and cabling. |
| Employee MacBooks and unlocked sessions | Elevation of privilege | A person at an unattended unlocked laptop uses the logged-in user's session to reach production or corporate systems. | Malicious insider or visitor | Critical: account takeover and lateral movement | Enforce automatic lock, short idle timeout, disk encryption, EDR/MDM, MFA, and clean-desk/screen policy. |
| Building keycards and spare-card box | Spoofing | Generic or unlabeled cards are borrowed, copied, or used after an employee leaves, defeating attribution. | Former employee or insider | High: unauthorized office and Core access | Issue named cards; inventory and revoke cards; secure spare cards; review access reports; prohibit sharing. |
| Office whiteboard and printed secrets | Information disclosure | Credentials visible in the open office are photographed or read by visitors, cleaners, or passers-by. | Visitor, contractor, or curious insider | Critical: direct access to guest Wi-Fi, staging DB, and accounts | Erase secrets immediately; rotate exposed credentials; prohibit secrets on whiteboards; use a secrets manager. |
| Switches, live ports, and office cabling | Tampering | An attacker plugs an unauthorized device into an unused live port or alters the spaghetti cabling to intercept or disrupt traffic. | Visitor or malicious insider | High: network interception, rogue access, or outage | Disable unused ports; use 802.1X/NAC where available; label and lock equipment; segment guest, corporate, and management networks. |
| Shared `nexus_master.pem` SSH key | Spoofing | Anyone who obtains the key authenticates as the shared production administrator, and the organization cannot identify the individual. | External attacker after Slack compromise or departing employee | Critical: full production takeover | Revoke and rotate the key; issue per-user keys; use MFA/bastion; least privilege; store secrets outside Slack; log commands. |
| Slack `#dev-ops` and deployment credentials | Information disclosure | A compromised Slack account or exported message exposes the shared private key and operational secrets. | Phished employee or compromised SaaS account | Critical: credential theft and follow-on compromise | Delete secrets from chat after rotation; enforce SSO/MFA; restrict channel membership; use a managed secret vault and retention controls. |
| Public PostgreSQL port 5432 | Spoofing | An attacker brute-forces or reuses database credentials over the Internet and authenticates directly to PostgreSQL. | Internet-based criminal or botnet | Critical: database theft or modification | Remove public exposure; allow only private subnet/bastion/VPN security groups; require TLS, strong unique credentials, and MFA through the access path. |
| Production database and application data | Tampering | A compromised application account or overprivileged developer modifies transaction or customer records without separation of duties. | Compromised application identity or malicious insider | Critical: financial-integrity and regulatory failure | Separate service/read/write roles; parameterized queries; migrations through reviewed CI/CD; database auditing; integrity checks and restore tests. |
| Admin panel and CEO PIN (`1975`) | Spoofing | The predictable PIN is guessed or credential-stuffed, allowing unauthorized administrative login. | Automated attacker or opportunistic insider | Critical: administrative takeover | Remove the PIN; require unique password plus phishing-resistant MFA; rate-limit and lock out; restrict admin access by role and network. |
| S3 database backup bucket and dump job | Denial of service | The abandoned or unverified dump job fails, or backups are deleted/corrupted before recovery is needed. | Ransomware actor, compromised cloud identity, or operational failure | Critical: unrecoverable outage and audit failure | Assign an owner; test scheduled encrypted backups; enable versioning/object lock; least-privilege bucket policy; cross-account/region copy and restore tests. |
| Production application and public API | Denial of service | An attacker floods the public service or exploits an unbounded request/resource path, making it unavailable. | Botnet operator or application-layer attacker | High: revenue and IPO disruption | Put WAF/rate limiting/CDN in front; set resource limits; health checks and autoscaling; alert on latency, errors, and saturation. |
| Linux hosts and root administration | Elevation of privilege | A developer with broad root access makes an unsafe change or an attacker turns a local foothold into total host control. | Compromised developer account or well-meaning administrator | Critical: complete host and data compromise | Remove routine root access; implement RBAC and `sudo` allowlists; patch; use MAC (AppArmor); separate admin accounts; require change review. |
| Central logging and monitoring | Repudiation | An intruder deletes or alters local logs, leaving no reliable record of the outage or unauthorized activity. | Attacker with host/root access | High: delayed detection and failed audit evidence | Forward logs in near real time to a separate hardened account; restrict write/delete permissions; use immutable retention, time sync, alerts, and access review. |
| Incident response process and contacts | Repudiation | The team cannot establish who did what or preserve evidence because ownership, escalation, and chain of custody are undefined. | Any attacker exploiting the response gap | High: prolonged breach and unreliable audit | Publish an IR plan; name on-call roles and contacts; define severity, evidence handling, communications, and tabletop/test the plan. |

## 4. Prioritized risk register

The following are the burning fires to address before the auditor arrives:

| Priority | Risk | Why it is urgent | Owner / evidence of closure |
|---|---|---|---|
| P0 | Public PostgreSQL access and shared production SSH key | Enables direct external compromise and untraceable full administrative access. | CTO/Cloud owner; security-group export, rotated-key record, and access test. |
| P0 | Exposed credentials on whiteboard and Slack | Secrets are already disclosed and must be assumed compromised. | CISO/IT; credential rotation report and secret-scanning result. |
| P0 | Uncontrolled physical access and open Core | A visitor can reach infrastructure without needing a software exploit. | Office Manager; visitor/card logs, door test, and rack inspection. |
| P0 | Unlocked laptops and excessive root privileges | A short physical opportunity can become a production compromise. | IT/Engineering; MDM compliance report and `sudo`/group review. |
| P1 | Unknown backup health and no centralized logs | Nexus may be unable to recover or prove what happened. | Cloud/Operations; successful restore, remote-log receipt, and alert test. |
| P1 | Predictable admin PIN and weak authentication | Easily automated account takeover of a high-value interface. | Application owner; MFA enforcement and failed-login/rate-limit test. |

## 5. Security requirements derived from the model

These requirements translate the risks into controls and are testable during the audit:

- No database or management service is reachable from the public Internet unless explicitly approved and protected by a documented control.
- Every human administrator has an individual identity, MFA, least privilege, and attributable logs; shared privileged credentials are prohibited.
- Secrets must not be stored in Slack, whiteboards, source code, or tickets. Exposed secrets are rotated immediately.
- Physical visitors are identified, logged, badged, escorted, and prevented from accessing the Core or unattended endpoints.
- Unused network ports are disabled, and guest, corporate, server, and management traffic are segmented.
- Logs are time-synchronized, forwarded to a separate system, access-controlled, retained according to legal and audit requirements, and monitored for critical events.
- Backups are encrypted, access-controlled, versioned/immutable where possible, monitored, and restored on a scheduled test cycle.
- Administrative interfaces require strong unique credentials, phishing-resistant MFA where supported, rate limiting, and role-based authorization.
- All production changes are attributable, reviewed, reversible, and recorded through the change/deployment process.

## 6. Residual risk and review

The five-day plan reduces the highest-probability paths to compromise but does not eliminate
risk. Co-working-space exposure, SaaS compromise, software vulnerabilities, insider abuse,
and availability events remain residual risks. The CISO should review this model after the
initial containment, after any material architecture change, and at least quarterly. Each
control owner must attach evidence to the audit report and record exceptions with an
expiry date and compensating control.
