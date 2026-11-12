# Vanguard Security: Threat Modeling Engagement Report
## Client: Meridian Federal Bank

**Prepared by:** Vanguard Security Junior Consultant  
**Date:** 2026-11-12  
**Distribution:** Meridian internal architecture team

## 1. Executive Summary

Meridian's transition from its legacy mainframe to a hybrid AWS/on-premises architecture creates a concentrated risk period: both environments will operate for six weeks, and the migration services, reconciliation process, and cutover controls will become trusted paths between them. Our STRIDE analysis identifies five priority engineering concerns, led by cross-environment privilege escalation, tampering or loss of integrity in reconciliation, and insufficient protection of cutover and rollback controls. These risks are material because an attacker who compromises a migration identity or administrative path could affect both the cloud and legacy environments while making the resulting activity difficult to attribute. Meridian should enforce distinct least-privileged identities, tamper-evident reconciliation, dual control for cutover, correlated monitoring, and tested rollback before the dual-running window begins. This report is intended to guide the architecture team; it is not a certification that the bank is compliant or free of exploitable vulnerabilities.

## 2. Engagement Context

Meridian is a federally regulated US regional bank with approximately 800 employees and more than 60 branches, operating a small Luxembourg subsidiary for expatriate US clients. Vanguard was engaged to identify risks introduced by the multi-year migration while the legacy mainframe and hybrid AWS/on-premises services run in parallel. The assessment is bounded by the Rules of Engagement to the migration architecture and its authorized data flows; the Luxembourg subsidiary is excluded. The six-week dual-running period, US financial-sector threat activity described in the briefing, and the need for an auditable transition make identity, integrity, availability, and evidence continuity the primary concerns.

## 3. Framework Choice and Rationale

Vanguard selected **STRIDE**. The migration architecture places a concrete AWS-to-on-premises synchronization path, a legacy mainframe, and dual-running reconciliation/cutover controls inside the assessment perimeter, making an architecture-element matrix directly actionable for Meridian's engineering audience. The Rules of Engagement focus the work on risks introduced by the transition state, while the US financial-sector threat-intelligence briefing provides context for prioritizing credential abuse, integrity attacks, and availability pressure against the STRIDE categories. STRIDE is therefore the appropriate first-pass lens for deciding which trust boundaries and controls the architecture team must strengthen before dual running; adversary-specific emulation and business-launch analysis would be separate follow-on work.

## 4. Threat Model

### Scope and boundaries

The modeled perimeter contains the AWS application/service tier, the on-premises legacy mainframe, the AWS-to-mainframe migration and synchronization flow, dual-running reconciliation and cutover controls, and the administrative/monitoring plane supporting those elements. It excludes the Luxembourg subsidiary and any asset not named in the signed Rules of Engagement. Exact hostnames, accounts, trust-boundary identifiers, and permitted actions must be reconciled to the authoritative architecture diagram and RoE before validation testing.

### STRIDE matrix

| Element | Spoofing | Tampering | Repudiation | Information disclosure | Denial of service | Elevation of privilege |
| --- | --- | --- | --- | --- | --- | --- |
| AWS application/service tier | Stolen workload or operator identity | Altered requests, deployments, or configuration | Cloud action not linked to a stable identity | Exposed service, log, or storage data | Resource exhaustion or control-plane abuse | Workload role escalates to cloud administration |
| Legacy mainframe / system of record | Forged migration/operator identity | Unauthorized account, transaction, or migration-state writes | Legacy events cannot be correlated to cloud activity | Batch, interface, or log exposure | Blocked/overloaded interface or batch | Broad migration account reaches unrelated functions |
| AWS-to-mainframe synchronization | Forged connector or replayed token | Changed records, mappings, order, or reconciliation results | Missing batch IDs/checksums/acknowledgements | Retry queues or staging expose records/secrets | Queue flooding, retries, or connector failure | Connector becomes a bridge to both environments |
| Dual-running reconciliation/cutover | Forged approval or release operator | Altered baseline, exception queue, feature flag | No immutable approval/decision trail | Broad reconciliation reports exposed | Inconsistent state or blocked rollback | One operator controls deployment and legacy data |
| Administrative/monitoring plane | Compromised admin/monitoring identity | Alerts, logs, IAM, or retention modified | Cloud/mainframe audit gaps | Central log store becomes a data trove | Saturated monitoring hides attack/outage | Monitoring/deployment role owns control plane |

### Priority findings

1. **F1 — Shared migration trust boundary may permit cross-environment privilege escalation (High).** A connector trusted by both AWS and the mainframe could turn one compromised identity into authority over both environments.
2. **F2 — Dual-running reconciliation may not provide tamper-evident integrity and attribution (High).** Altered records or exceptions could affect the system of record without a defensible account of which side accepted the change.
3. **F3 — Cutover and rollback controls are a privileged attack target (High).** Spoofed approval or altered configuration could create an unsafe migration state or prolong an outage.
4. **F4 — Audit and monitoring discontinuity may create repudiation and detection gaps (Medium-High).** Uncorrelated cloud and mainframe events would delay detection and investigation.
5. **F5 — Retry and failure handling may create availability or disclosure risk (Medium-High).** Unbounded retries, queue growth, or verbose error records could interrupt processing or expose sensitive data.

## 5. Recommendations and Prioritization

1. **Separate and constrain migration identities before dual running.** Give every connector, batch job, deployment process, and operator a unique identity. Enforce mutual authentication, least privilege, network allowlisting, short-lived credentials where supported, explicit destination permissions, and independent credential rotation. Confirm that compromise of an AWS workload cannot directly produce mainframe administrative authority.
2. **Make synchronization and reconciliation tamper-evident.** Add immutable batch and transaction identifiers, sequence/order validation, checksums or authenticated integrity protection, acknowledgements, replay detection, and append-only evidence for accepted/rejected changes. Require an independently reviewed exception queue and reconciliation report before a batch can be treated as complete.
3. **Protect cutover and rollback with separation of duties.** Separate the person who prepares a cutover from the person who approves and executes it. Protect feature flags and deployment configuration, require dual approval for production transition, alert on unauthorized changes, verify backups and rollback dependencies, and conduct a controlled rollback rehearsal before the six-week window.
4. **Unify audit and detection across both environments.** Correlate cloud, connector, reconciliation, and mainframe events using a common transaction/batch ID, identity, and time source. Send protected copies to monitoring that the migration administrators cannot silently alter. Alert on unusual connector volume, privilege changes, replay/order failures, queue growth, and attempts to disable logging.
5. **Bound retries and protect failure paths.** Define back-pressure, circuit breakers, dead-letter handling, recovery ownership, and maximum retry behavior. Redact customer data and credentials from errors and queues, encrypt retained messages, monitor queue health, and make a safe fail-closed or controlled-degraded mode explicit.

## 6. Limitations and Uncertainty

This report is a threat-modeling deliverable, not an exploit validation, compliance opinion, penetration-test result, or guarantee of security. The local engagement package available for drafting contained the engagement brief and descriptions of the architecture diagram, business context, threat-intelligence briefing, and Rules of Engagement, but not the interactive diagram or the full-text source documents. Consequently, exact hostnames, account IDs, IP ranges, connector names, trust-boundary labels, RoE clauses, and threat-intelligence indicators must be verified against Meridian's authoritative materials before implementation decisions are finalized. No hidden connection or undocumented asset has been treated as discovered, and no out-of-scope asset has been modeled. The Luxembourg subsidiary is explicitly excluded from this model and report's assessed perimeter; its regulatory and technical posture requires a separate authorization and assessment. Regulatory references are context for risk prioritization, not legal advice or a determination of OCC, GLBA, SOX, or Luxembourg compliance.

## 7. Appendix: Sourced Findings

The findings below are traceable to the supplied engagement materials and are stated as architectural risks requiring validation:

- **F1 / F2 / F3:** derived from the business context's multi-year migration and six-week dual-running period, together with the migration architecture described as hybrid AWS/on-premises and the requirement to identify transition-state risks.
- **F4:** derived from the need to operate and reconcile legacy and cloud environments during the transition, and from STRIDE's repudiation and detection concerns.
- **F5:** derived from the same dual-running data-flow boundary and the availability requirement implied by Meridian's banking operations.
- **Prioritization context:** derived from the supplied description of the US financial-sector threat-intelligence briefing and Meridian's US regulated-bank profile.

The interactive diagram, full Rules of Engagement, and threat-intelligence briefing should be attached to the review record and used to replace the remaining “verify before validation” assumptions before this report is issued to Meridian.
