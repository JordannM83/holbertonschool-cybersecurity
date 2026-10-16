# NovaTech Patch Management Policy

**Policy owner:** Chief Information Security Officer (CISO)  
**Applies to:** NovaTech servers, workstations, applications, operating systems, and third-party components  
**Review cycle:** At least annually and after any material security incident

## 1. Purpose and Scope

This policy establishes how NovaTech identifies, evaluates, tests, approves, deploys, verifies, and records software and operating-system patches. It applies to production, development, test, backup, and cloud-hosted systems managed by NovaTech or its service providers.

The objectives are to reduce exposure to known vulnerabilities, preserve service availability, prevent unauthorized changes, and provide evidence of responsible patch management to auditors and the board.

## 2. Roles and Responsibilities

- **CISO:** Owns this policy, approves risk exceptions, and reviews compliance reports.
- **Security team:** Monitors vulnerability advisories and CVEs, assigns patch classifications, and validates remediation.
- **Systems/platform team:** Maintains repositories and automation, tests patches, deploys approved updates, and maintains rollback capability.
- **Application owners:** Test business applications, identify compatibility risks, and approve service-impacting changes.
- **Service owners:** Confirm maintenance windows, communicate outages, and verify service health after patching.
- **Change management:** Records normal and emergency changes, approvals, implementation results, and backout plans.
- **All personnel:** Report suspected patch failures and must not bypass approved update controls.

## 3. Patch Classification

Patches are prioritized by exploitability, business impact, and affected asset:

| Classification | Examples | Target action |
|---|---|---|
| **Critical** | Active exploitation, remote unauthenticated compromise, ransomware, or severe internet-facing flaws | Emergency mitigation immediately; patch within 24 hours where feasible |
| **High** | High-impact CVEs, privilege escalation, authentication bypass, or exposed critical services | Patch within 7 days |
| **Medium** | Limited-impact vulnerabilities, local exploitation, or defense-in-depth fixes | Patch within 30 days |
| **Low** | Minor security improvements, stability fixes, or low-risk defects | Patch during the next planned maintenance cycle |

Security patches take precedence over feature updates. Unsupported software must be upgraded or replaced under a tracked remediation plan.

## 4. Update Schedule

Automatic updates are restricted to approved security origins. Package-list refreshes run during the maintenance window at **02:00**, with a 30-minute randomized delay. Security package installation runs at **03:00**, with a 60-minute randomized delay. The effective window is 02:00–05:00 local server time.

Apache, MySQL, Nginx, Docker, and other protected services are not automatically upgraded. They require human review, testing, and an approved change. Automatic reboot is enabled only when required by a kernel or core-library update, is scheduled for **04:00**, and is suppressed while users are logged in.

Before deployment, updates are simulated where possible. After deployment, package state, service health, listening ports, and application checks are verified.

## 5. Protected Packages

The following packages are blacklisted from unattended upgrades because an unreviewed change could interrupt critical web, database, or infrastructure services:

- `apache2`
- `apache2-bin`
- `mysql-server`
- `mysql-server-*`
- `nginx`
- `docker-ce`

Blacklist entries do not permanently waive security obligations. They require manual review and controlled deployment. A package hold is an additional temporary control and must include a documented reason, owner, start date, and review date.

## 6. Exception Process

An exception or package hold must be recorded in the change/hold registry and include:

1. Package name and affected systems
2. Reason, risk, and business owner
3. Compensating controls and monitoring
4. Planned remediation or review date
5. Approval from the service owner and CISO, where risk is High or Critical

Holds are reviewed at least every 30 days and must not remain indefinitely. The reviewer must test whether the upstream issue is resolved, release the hold when safe, and verify that the package receives the next approved update. New blacklist entries follow the same approval process and must not be used to hide failed patching.

## 7. Emergency Patching

For active exploitation or a Critical vulnerability:

1. Security opens an emergency change and identifies affected assets.
2. The team applies immediate mitigations such as isolation, access restrictions, service disablement, or vendor workarounds.
3. A tested patch is deployed to a representative system as quickly as practical.
4. The change owner obtains emergency approval from the CISO or delegate and deploys in prioritized waves.
5. The team monitors logs, service health, and indicators of compromise during and after deployment.
6. If the patch causes a regression, the team uses the recorded snapshot/package version to roll back, keeps compensating controls active, and escalates to the vendor.
7. The incident and emergency change records are completed within one business day.

Emergency changes may occur outside the normal maintenance window, but they must still be logged, approved retrospectively when necessary, verified, and reviewed.

## 8. Compliance and Auditing

Compliance is verified through monthly reviews and after every emergency change. Evidence includes:

- APT source and unattended-upgrades configuration backups
- Security-only update simulations and deployment results
- Package versions, holds, blacklist entries, and exception approvals
- DPKG/APT consistency and lock/operation diagnostics
- Service, port, configuration, and application health checks
- Automatic reboot and systemd timer status
- `/var/log/unattended-upgrades/` logs and `/var/log/package_holds.log`
- Archive checksums for exported patch-management configuration

The security team reports overdue Critical and High patches, holds older than 14 days, failed updates, and unauthorized repository changes to the CISO. Findings are tracked to closure. This policy is reviewed annually, after material platform changes, and after any patch-related incident.
