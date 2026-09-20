# Nexus Financial Incident Response Playbook

## Compromised Database

**Owner:** Interim CISO
**Primary technical responders:** Sarah (Lead Developer) and Dave (CTO)
**Severity:** Critical / P0
**Purpose:** Contain unauthorized database access while preserving evidence, protecting customers, and restoring a trusted service.

This playbook applies when Nexus detects suspicious PostgreSQL logins, unexpected data
changes or exports, a compromised application credential, ransomware, or an exposed
database host. Anyone may declare a suspected incident. Do not wait for certainty before
containing an active attacker.

### Roles

- **Sarah:** technical incident lead; coordinates evidence capture, host isolation,
  application shutdown, and rebuild actions.
- **Dave:** executive incident owner; approves business-impacting containment, coordinates
  cloud/provider access, legal/privacy counsel, customers, and the board/auditor.
- **CISO or incident scribe:** maintains the timeline, decisions, hashes, tickets, and chain
  of custody. If unavailable, Dave assigns a named substitute.
- **Do not communicate externally** about the incident until Dave and legal/privacy counsel
  approve the message.

## 1. Identification

### Trigger conditions

Treat any of these as a suspected database compromise:

- A login from an unknown source, unusual country, impossible travel, or an unexpected role.
- Repeated authentication failures followed by success, especially on port 5432.
- Unexpected `INSERT`, `UPDATE`, `DELETE`, `DROP`, role creation, schema change, or bulk export.
- A database credential, `nexus_master.pem`, admin PIN, or backup credential exposed in Slack,
  source code, a whiteboard, a ticket, or a public post.
- Unexpected CPU/memory/network activity, missing logs, disabled auditing, or a ransom note.
- A user, application, or monitoring alert reports customer-data access they cannot explain.

### First 15 minutes

1. Sarah opens a P0 incident ticket and records the reporter, UTC time, alert, affected host,
   database, account, source IP, and business symptoms. Dave is paged immediately.
2. Sarah confirms the alert using an independent source: PostgreSQL/authentication logs,
   centralized logs, cloud flow logs, host audit logs, or the application audit trail.
3. Preserve volatile evidence before rebooting or deleting anything when this does not allow
   continued attacker access: active connections, processes, routes, cloud security-group
   state, relevant log files, and timestamps. Copy evidence to a separate restricted store,
   hash it, and record who collected it.
4. Do not run cleanup commands, rotate logs, install tools on the suspected host, or edit
   suspicious files before evidence is captured. Do not accuse an employee based on one log.
5. Record the incident scope as **suspected**, **confirmed**, or **not confirmed**. A lack of
   logs is itself an incident finding and must not be treated as proof of safety.

## 2. Containment

Containment prioritizes stopping further access while retaining a usable recovery path.
Dave approves customer-visible outage actions; Sarah performs them and records exact times.

### Immediate containment

1. Remove public database exposure. Change the cloud security group and host firewall so
   PostgreSQL `5432/tcp` accepts only the application private address and approved bastion/
   incident path. Remove every `0.0.0.0/0` rule.
2. If compromise is active, isolate the database host from the network or place it in a
   quarantine security group. Keep a controlled forensic connection from the bastion only.
3. Disable the suspected database, application, backup, cloud, and human accounts. Revoke
   sessions, API tokens, SSH keys, VPN access, and any credentials stored with them.
4. Stop the application or put it into a read-only/maintenance mode if it can continue
   issuing destructive queries. Block suspicious source IPs at the WAF/security group.
5. Preserve the database volume/snapshot as evidence. Do not delete the compromised instance
   until Sarah and legal/forensics approve it.

### Credential containment

- Assume all credentials visible to the compromised host or account are exposed.
- Rotate the PostgreSQL application, migration, backup, monitoring, cloud, CI/CD, and
  administrator credentials from a known-clean workstation using the secrets manager.
- Revoke `nexus_master.pem` everywhere. Replace it with individual, short-lived identities;
  never paste replacement secrets into Slack.
- Force MFA reauthentication for affected human accounts and review recent identity-provider
  sessions and access logs.
- Preserve the old credentials in restricted incident records only when required for evidence;
  never leave them active for convenience.

## 3. Eradication

Eradication begins only after evidence and a recovery point are secured.

1. Determine the initial access path: public PostgreSQL, stolen SSH key, application
   vulnerability, cloud identity, endpoint, backup, or insider action. Record confidence and
   unknowns; do not guess in the final report.
2. Compare database roles, grants, schemas, extensions, scheduled jobs, triggers, tables,
   recent migrations, and application configuration against the last known-good baseline.
3. Search the database host and application hosts for unauthorized users, SSH keys, cron jobs,
   systemd units, binaries, containers, web shells, altered files, and persistence. Review
   audit, PostgreSQL, application, cloud, and centralized log timelines together.
4. Patch or remove the exploited vulnerability. Correct the security group, firewall, IAM
   policy, application flaw, or exposed secret that enabled access. Add a regression test.
5. Do not trust an in-place cleanup of a root-compromised server. Build a new host from a
   pinned, patched image; apply hardening, RBAC, AppArmor, firewall, logging, and monitoring
   before attaching production data.
6. Revoke unknown database roles and grants, remove unauthorized objects, and rotate all
   secrets again if the attacker could have observed the first rotation.

## 4. Recovery

1. Select the most recent known-good backup from before the compromise. Verify its integrity,
   provenance, encryption, and timestamp. If no known-good backup exists, escalate to Dave,
   legal, and the recovery provider before modifying data.
2. Restore into an isolated recovery environment. Run schema, application, malware, integrity,
   and reconciliation checks. Confirm transaction totals and customer records with the data
   owner before production use.
3. Deploy the clean patched host and application using the reviewed pipeline. Keep the old
   host isolated and read-only for evidence.
4. Enforce the new private network path: application-to-database only, bastion-only SSH,
   TLS, least-privilege database roles, MFA for administration, and no public `5432`.
5. Confirm centralized logs are arriving from the new host, audit rules are active and
   immutable, alerts fire, backups succeed, and restore testing passes.
6. Re-enable service gradually: smoke test, read-only test, controlled writes, then normal
   traffic. Monitor authentication, queries, errors, CPU, memory, connections, and egress
   continuously for at least the agreed heightened-monitoring period.
7. Dave and legal/privacy counsel determine whether customers, regulators, insurers, the
   auditor, or law enforcement must be notified. Preserve notification decisions and dates.

### Recovery exit criteria

Recovery is complete only when:

- The entry path is closed or has an approved compensating control.
- All exposed secrets are rotated and unknown identities are revoked.
- Restored data is reconciled and approved by its owner.
- The replacement host passes hardening, vulnerability, access, logging, and backup checks.
- Monitoring shows no unexplained access or persistence during the heightened-monitoring period.
- Dave accepts residual risk in writing and the incident record contains evidence and decisions.

## 5. Lessons learned

Within five business days of recovery, Sarah facilitates a blameless review and Dave signs
the resulting action plan. The review must answer:

- What happened, when, and how was it detected?
- Which data, accounts, systems, and customers were affected, and what remains unknown?
- Why did prevention, logging, alerting, backup, or response controls fail?
- Which evidence supports each conclusion, and what is the confidence level?
- What was the actual recovery point and recovery time?
- Which actions are required, who owns them, what is the due date, and what evidence proves closure?

At minimum, test and document these improvements:

- PostgreSQL is private and allowlisted; public exposure is continuously checked.
- Individual MFA identities and short-lived SSH access replace shared keys.
- Database auditing, centralized immutable logs, time synchronization, and alerting are tested.
- Backups are encrypted, immutable/versioned where possible, monitored, and restored regularly.
- Production database roles, application permissions, and break-glass access are reviewed.
- The team conducts a tabletop exercise and updates contacts, diagrams, commands, and this
  playbook after every material architecture or staffing change.
