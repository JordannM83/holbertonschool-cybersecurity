# Meridian Federal Bank — Threat Model

## Framework Declaration

**STRIDE**

## Rationale

STRIDE is the best fit for Meridian's internal architecture team because the engagement is centered on a concrete migration architecture and a six-week period in which the legacy mainframe and hybrid AWS/on-premises environment will run in parallel. The Rules of Engagement define an assessment perimeter around risks introduced by that transition, so a system-element and data-flow matrix will translate directly into engineering changes. The US financial-sector threat-intelligence briefing supplies realistic attacker pressure to use when prioritizing the STRIDE results, while the bank's US regulatory context makes integrity, confidentiality, and auditability concrete design concerns. This is a technical architecture decision rather than a board-level launch decision, so STRIDE's element-to-threat mapping is more immediately actionable than a business-first risk narrative or an adversary-emulation catalog.

## Framework Selection Feedback

STRIDE's Meridian-specific strength is that it forces the architecture team to inspect each migration trust boundary for spoofing, tampering, repudiation, information disclosure, denial of service, and elevation of privilege instead of treating “hybrid migration risk” as one vague issue. Its limitation is that it does not by itself rank threats by the bank's most likely adversaries or model the full business impact of a six-week transition; the threat-intelligence briefing and the migration cutover plan must provide that prioritization context.

## Threat Model

### Scope and assumptions

This model covers only the in-scope migration elements described in the engagement brief and Rules of Engagement: the hybrid AWS/on-premises transition, the legacy mainframe during dual running, and the migration data flows and controls connecting them. The Luxembourg subsidiary is excluded and is not modeled here. Exact component labels, trust-boundary identifiers, and allowed test actions must be reconciled against the signed architecture diagram and RoE before technical validation begins.

### STRIDE matrix

| Architecture element / boundary | S — Spoofing | T — Tampering | R — Repudiation | I — Information disclosure | D — Denial of service | E — Elevation of privilege |
| --- | --- | --- | --- | --- | --- | --- |
| **AWS application and service tier** | Stolen service, operator, or workload credentials could impersonate an authorized caller. | An attacker with a foothold could alter application configuration, deployment artifacts, or requests before they reach the system of record. | Incomplete identity propagation across cloud services could prevent attribution of an administrative or data-changing action. | Exposed logs, service endpoints, or mis-scoped storage could disclose customer or transaction data. | Resource exhaustion, malicious requests, or control-plane abuse could interrupt customer-facing banking functions. | A compromised workload identity or overly broad role could become an administrative cloud identity. |
| **On-premises legacy mainframe / system of record** | Weak migration-era authentication or shared credentials could allow an attacker to present as a trusted migration process or operator. | Unauthorized writes to account, transaction, or migration state could corrupt the authoritative record. | Legacy audit records may not correlate with the cloud transaction ID, user, or migration batch. | Batch files, interfaces, logs, or operator channels could expose regulated financial information. | A blocked batch, unavailable interface, or overloaded legacy service could break processing during dual running. | A migration account with broad mainframe privileges could be used to reach unrelated banking functions. |
| **AWS-to-mainframe migration and synchronization flow** | A forged connector identity or replayed token could submit data as a trusted migration job. | Records, mappings, sequence numbers, or reconciliation results could be changed in transit or at the receiver. | Missing immutable batch IDs, checksums, or acknowledgements could make it impossible to prove which side accepted a change. | The transition channel, staging area, or retry queue could reveal full records or credentials. | Queue flooding, repeated retries, or connector failure could create backlogs and interrupt dual-running reconciliation. | A connector trusted for data movement could be abused to invoke privileged operations on both sides. |
| **Dual-running reconciliation and cutover controls** | An attacker could impersonate an approver or release operator and authorize a cutover or exception. | Reconciliation baselines, exception queues, feature flags, or cutover configuration could be altered. | Without signed approvals and immutable decision logs, the bank could not establish who approved a migration state. | Reconciliation reports and exception records could expose broad customer or transaction populations. | An attacker could keep the systems in an inconsistent state or prevent a safe cutover/rollback. | A release or reconciliation operator may have simultaneous access to cloud deployment and legacy data controls. |
| **Administrative and monitoring plane within the migration perimeter** | Compromised administrator or monitoring credentials could hide as a trusted operator. | Alert rules, retention settings, IAM policy, or deployment configuration could be modified to weaken controls. | Gaps between cloud audit logs and mainframe audit logs could allow privileged activity to be denied. | Centralized logs and monitoring exports could become a high-value concentration of sensitive data. | Log or monitoring saturation could remove the team's ability to detect a migration attack or outage. | A monitoring or deployment role with excessive permissions could be chained into control-plane ownership. |

### Threat actors and prioritization context

The threat-intelligence briefing should be used to validate which STRIDE cells receive highest test priority, especially activity relevant to US financial institutions and credential- or ransomware-driven intrusion. The immediate engineering priority is not a generic list of every STRIDE category; it is the set of threats that can alter or suppress a payment/account record during dual running, abuse a connector trusted by both environments, or prevent reliable detection and rollback. The model does not assign risk to the excluded Luxembourg subsidiary or to assets not identified in the RoE.

### Control questions for validation

1. Does every migration connector authenticate with a unique, least-privileged identity, mutually authenticate across the boundary, and reject replayed or reordered messages?
2. Are transaction identifiers, sequence numbers, checksums, acknowledgements, and reconciliation exceptions tamper-evident and independently auditable on both sides?
3. Can the bank prove which human or workload approved a migration batch, changed a cutover control, or performed a privileged data operation?
4. Are cloud and mainframe privileges separated so that compromise of one connector, operator, or deployment role does not provide control of both systems?
5. Can the bank detect connector abuse, queue flooding, unauthorized configuration changes, and suppression of audit logs quickly enough to invoke rollback?
6. Are rollback, fail-closed behavior, backup integrity, and recovery objectives tested before the six-week dual-running window begins?

## Identified Findings

1. **F1 — Shared migration trust boundary may permit cross-environment privilege escalation (High).** A connector trusted by both AWS and the legacy mainframe creates a high-impact STRIDE intersection: spoofing, tampering, and elevation of privilege could turn one compromised workload or credential into authority over both environments. Validate unique identities, mutual authentication, least privilege, network restriction, credential rotation, and a one-way or narrowly scoped permission model where possible.
2. **F2 — Dual-running reconciliation may lack tamper-evident integrity and attribution (High).** During the six-week transition, inconsistent records or altered exception handling could affect the system of record while leaving the architecture team unable to prove which side accepted a change. Require immutable batch IDs, sequence and integrity checks, signed or append-only reconciliation evidence, correlated audit events, and an independently reviewed exception workflow.
3. **F3 — Cutover and rollback controls are a privileged attack target (High).** Spoofed approval, modified feature flags, or unavailable rollback dependencies could cause an unsafe migration state or prolonged service interruption. Separate approval and execution privileges, require dual control for cutover, protect configuration from unauthorized change, alert on deviations, and rehearse rollback before production dual running.
4. **F4 — Audit and monitoring discontinuity across cloud and mainframe can create repudiation and detection gaps (Medium-High).** If identities, timestamps, transaction IDs, and administrative events are not normalized across both environments, the bank may not detect or investigate a migration attack in time. Define a common event schema, centralize protected copies of logs, monitor connector behavior and privileged changes, and test alert delivery during failover.
5. **F5 — Migration retries and failure handling may create availability and disclosure risk (Medium-High).** Unbounded retries, queue growth, or verbose dead-letter/error records could interrupt processing or expose regulated records and credentials. Set bounded retries, back-pressure and circuit breakers, health-based stop conditions, redacted errors, protected queues, and an operator-controlled recovery procedure.
