# Vanguard Security: Threat Modeling Engagement Report
## Client: Helix Aerospace Systems

**Prepared by:** Vanguard Security Junior Consultant  
**Date:** 2026-11-12  
**Distribution:** Helix CISO (with downstream BSI / DGA review)

## 1. Executive Summary

Helix can support the BSI operational contract and the pending DGA negotiation only with an evidence-based claim that its European-sovereign SaaS platform can prevent, detect, contain, and recover from the behaviors named in the contract. MITRE ATT&CK mapping identifies the highest-consequence paths as compromised valid accounts or tokens crossing tenant boundaries, exploitation of public-facing SaaS/API services, credential and secret reuse through CI/CD or workloads, defense impairment, and data encryption or exfiltration. The principal risk is not that any one technique exists in the abstract; it is that a single compromised identity, workload, or administrative path could undermine isolation across aerospace customers while leaving Helix unable to prove what happened or restore service. Before using this report as BSI or DGA evidence, Helix should reconcile the exact contract technique list and the italicized emerging behavior in the BSI threat note, then run controlled validation exercises with evidence for prevention, detection, containment, and recovery. The architecture's European sovereignty and BSI C5 attestation are valuable foundations, but neither alone proves resistance to the named adversaries.

## 2. Engagement Context

Helix is a Munich-based, 120-person B2B SaaS provider for aerospace and defense analytics, operating a multi-tenant platform on European-sovereign OVHcloud and Deutsche Telekom T-Systems infrastructure and deliberately serving no US government clients. The BSI contract is entering its operational phase, while the DGA contract is pending; together they represent approximately half of forecast revenue. Both engagements reference resilience against a state-aligned cluster commonly attributed to Russia and an opportunistic financially motivated cluster active against European defense suppliers, making the BSI unclassified threat note and the contractual technique list operationally and commercially consequential.

## 3. Framework Choice and Rationale

Vanguard selected **MITRE ATT&CK Enterprise**. The BSI threat note is the most operationally important source because the contract specifies adversary behaviors Helix must demonstrate resilience against, and ATT&CK gives BSI, DGA, ANSSI-aligned procurement, and NATO interoperability readers a common technique vocabulary. The product architecture's European-sovereign cloud topology and multi-tenant isolation model can then be mapped to concrete attack paths involving identity, public SaaS/API exposure, workloads, CI/CD, tenant boundaries, and recovery. This is materially different from Meridian's STRIDE architecture decomposition and Sundara's PASTA business-decision progression: Helix needs adversary-behavior traceability and exercise evidence tied to contractual claims.

## 4. Threat Model

### Scope and attribution boundary

The model covers Helix's authorized multi-tenant SaaS, European-sovereign cloud topology, identity and administrative plane, APIs and application workloads, data/storage services, CI/CD, logging/detection, and recovery controls. It does not profile named individuals in stakeholder materials. The two adversary profiles are referred to conservatively as **Cluster R** (state-aligned, commonly attributed to Russia) and **Cluster F** (opportunistic financially motivated activity) until the exact names and technique references in the contract and BSI note are verified.

### Contract-linked ATT&CK matrix

| ATT&CK behavior | Cluster R | Cluster F | Helix target/path | Required resilience evidence |
| --- | --- | --- | --- | --- |
| T1566 Phishing | Initial access to privileged or supplier identities | Credential or malware delivery | Identity and support access | MFA, mail/web controls, reporting, alerting, and containment exercise |
| T1190 Exploit Public-Facing Application | Exploit SaaS/API weakness | Exploit exposed service for access or extortion | Public API, application, management surface | Patch/SAST/DAST evidence, safe exploit validation, WAF/API telemetry |
| T1078 Valid Accounts | Abuse compromised cloud/support/admin credentials | Monetize access without noisy exploitation | SSO, tenant admin, service accounts | Least privilege, MFA, anomaly detection, revocation, access reviews |
| T1059 Command and Scripting Interpreter | Execute in workload or admin tooling | Execute in compromised host/runner | Containers, bastions, CI/CD | Runtime restrictions, command telemetry, response evidence |
| T1021 Remote Services | Move through management paths | Move from operator endpoint or exposed service | Bastions, cluster nodes, admin plane | Segmentation, JIT access, session records, alerts |
| T1552 Unsecured Credentials | Find secrets in images, configuration, logs, repositories | Reuse exposed credentials | CI/CD, images, vaults, logs | Secret scanning, vaulting, rotation, redaction |
| T1550 Use Alternate Authentication Material | Reuse tokens/cookies to bypass authentication | Reuse API keys or refresh tokens | SaaS sessions and workload credentials | Short-lived/bound tokens, replay detection, revocation |
| T1562.001 Impair Defenses | Modify logging/security tooling | Disable controls before theft or ransomware | Monitoring, EDR/runtime, IAM | Immutable logs, tamper alerts, separated administration |
| T1567 Exfiltration Over Web Service | Extract engineering/tenant data quietly | Steal customer data for leverage | APIs, storage, support exports, egress | Egress control, analytics, export approvals, containment |
| T1486 Data Encrypted for Impact | Disruption pressure if access persists | Ransomware/extortion | Tenant data, backups, deployment/storage | Isolated immutable backups and restore exercise |
| Emerging BSI-note behavior | Exact mapping pending source verification | Exact mapping pending source verification | Depends on the note's wording | Custom annotation only after confirming the PDF and control test |

### Contractual resilience interpretation

For each named technique, Helix should present a trace from ATT&CK technique to affected asset and tenant boundary, preventive control, detection signal, response owner, and test evidence. “C5-attested” and “European-sovereign” describe important assurance and hosting properties, but they do not substitute for technique-specific validation. The resilience claim should distinguish a control that prevents the behavior from a control that detects it after execution, and should state the recovery objective where a technique can affect availability or data integrity.

## 5. Recommendations and Prioritization

1. **Close the contractual evidence map before external review.** Transcribe the exact adversary names and technique IDs from the signed BSI excerpts and threat note, identify the ATT&CK version used, and map each technique to Helix's assets, control owners, detection, containment, and recovery evidence. Do not claim coverage for a technique that has not been exercised or otherwise evidenced.
2. **Prove tenant isolation under identity compromise.** Test T1078 and T1550 scenarios with approved accounts and tokens, including role changes, API authorization, support access, session revocation, and cross-tenant object requests. A compromised tenant user or workload must not reach another customer's data or administrative plane.
3. **Harden the public application and software supply chain.** Prioritize T1190, T1552, and T1059 controls: patch critical exposed components, enforce secure build provenance, scan repositories/images, remove secrets from artifacts, isolate CI/CD runners, and restrict workload identities and execution.
4. **Make defense impairment visible and difficult.** Protect logging and detection administration from the same identities that operate workloads, send immutable copies to a separate security boundary, alert on telemetry gaps and policy changes, and rehearse response to T1562.001.
5. **Demonstrate recovery against financially motivated disruption.** Maintain isolated backups, separate backup credentials and keys, verify tenant-level restoration, and execute a T1486 recovery exercise with documented recovery time and data-loss objectives.
6. **Handle the emerging TTP as a controlled extension.** Once the BSI PDF is available, define the behavior in plain language, record why no published ATT&CK technique is an exact fit, assign a temporary identifier, name affected assets and controls, and disclose the annotation's emerging status in the BSI/DGA evidence pack.

## 6. Limitations and Uncertainty

This report is a threat model and resilience-evidence plan, not a penetration-test result, BSI C5 certification, DGA qualification, or guarantee against the named clusters. The local engagement package available for drafting contained the assignment brief and descriptions of the architecture, business context, stakeholder, threat-note, and Rules of Engagement materials, but not the full intranet documents or BSI PDF. The exact adversary names, ATT&CK technique IDs, ATT&CK version, scope exclusions, and italicized emerging TTP must therefore be verified before this report is used as contractual evidence. The emerging behavior is intentionally not invented or mapped to an unrelated published technique; it remains an open source-validation item. Sovereign hosting and C5 attestation reduce certain platform and assurance risks but do not prove tenant isolation, identity resilience, detection, or recovery. No stakeholder individual is treated as an insider threat; personnel risk must be assessed through authorized role, access, and behavior controls rather than personal profiling.

## 7. Appendix: Sourced Findings

- **F1 — Contractual technique evidence gap:** sourced from the business context's BSI-signed and DGA-pending contract references to named adversary clusters and from the instruction that the BSI threat note specifies the operational TTP requirement.
- **F2 — Tenant-boundary impact:** sourced from the product architecture's multi-tenant SaaS model and the requirement to assess the European-sovereign cloud topology.
- **F3 — Identity, secrets, and public-service attack paths:** mapped to the ATT&CK techniques listed in the working model and to the cloud/application/CI-CD components described in the engagement brief; exact applicability must be confirmed against the diagram and RoE.
- **F4 — Recovery and defense impairment:** sourced from the contractual resilience objective and the need to demonstrate resistance, not merely document preventive configuration.
- **F5 — Emerging TTP:** **EMERGING STATUS — source verification required.** The BSI note reportedly italicizes one TTP as emerging and not yet present in published ATT&CK matrices. Because the PDF is unavailable in the local workspace, its wording, actor mapping, and asset impact are not asserted here. Once obtained, it belongs in the final appendix as a custom annotation with explicit version and evidence references.

Before forwarding to BSI or DGA, Helix should attach the source-controlled contract excerpts, BSI threat note, architecture diagram, and Rules of Engagement, then replace the provisional Cluster R/Cluster F labels and open emerging-TTP item with the exact source language.
