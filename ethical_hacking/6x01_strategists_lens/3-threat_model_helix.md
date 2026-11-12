# Helix Aerospace Systems — Threat Model

## Framework Declaration

**MITRE ATT&CK Enterprise**

## Rationale

MITRE ATT&CK is the appropriate framework for Helix because the BSI contract and its threat note make resilience against named adversary clusters and documented TTPs a contractual claim, not merely a generic architecture review. The European-sovereign cloud topology and multi-tenant isolation model need to be evaluated as attack paths across identity, cloud workloads, tenant boundaries, and the control plane, while ATT&CK provides a common vocabulary for adversary behavior that BSI, DGA, ANSSI-aligned procurement staff, and NATO evaluators can recognize. The business context also makes evidence of detection, containment, and recovery against the state-aligned and financially motivated clusters more useful than a purely structural threat list. The exact cluster names and technique references must be transcribed from the signed contract excerpts and BSI threat note before this model is issued as contractual evidence.

## Framework Selection Feedback

ATT&CK's Helix-specific strength is traceability: each resilience claim can be tied to an adversary behavior, a Helix asset, a preventive/detective control, and an evidence-producing validation activity. Its limitation is that published ATT&CK describes behavior rather than proving tenant isolation, cloud-sovereignty, contractual compliance, or recovery; Helix still needs architecture, control, and exercise evidence around each technique. Stakeholder names are not modeled as threats or attributed behaviors.

## Threat Model

### Scope and modeling conventions

The model covers Helix's European-sovereign multi-tenant SaaS platform, its tenant-isolation controls, identity and administrative plane, application/API workloads, storage and data services, logging/detection, CI/CD and administrative access, and the authorized supporting cloud infrastructure identified in the Rules of Engagement. It does not profile named individuals from stakeholder materials. A threat actor is modeled by observed or contractually named behavior, not by an employee's identity or personal characteristics.

The two contract-referenced profiles are labeled below as **Cluster R (state-aligned, commonly attributed to Russia)** and **Cluster F (opportunistic financially motivated activity against European defense suppliers)** until the exact names in the contract excerpts are verified. This naming is deliberately conservative: no particular public group is asserted without the source contract and BSI note.

### ATT&CK technique-to-asset matrix

| ATT&CK technique / behavior | Cluster R | Cluster F | Helix asset / attack path | Resilience evidence to require |
| --- | --- | --- | --- | --- |
| **T1566 — Phishing** (including relevant sub-techniques from the contract) | Likely initial access against privileged or supplier identities; exact sub-technique must be confirmed from the BSI note | Likely credential or malware delivery against staff and support users | Identity plane, admin access, support tooling | Tested mail/web controls, phishing-resistant authentication where feasible, alerting, user-report route, and containment evidence |
| **T1190 — Exploit Public-Facing Application** | Potential exploitation of SaaS/API weaknesses to reach tenant or control-plane paths | High-value route to exposed application services and data | Public SaaS endpoints, API gateway, authentication, management interfaces | Secure SDLC evidence, patch SLAs, WAF/API controls, reproducible negative tests, and detection of exploit patterns |
| **T1078 — Valid Accounts** | Use of compromised cloud, support, or tenant administrator credentials | Common route to monetize SaaS access without noisy exploitation | SSO, privileged roles, service accounts, tenant administration | MFA/conditional access, least privilege, short-lived credentials, anomaly detection, rapid revocation, and access reviews |
| **T1059 — Command and Scripting Interpreter** | Post-compromise execution in workloads or administration tooling | Execution in compromised hosts or automation runners | Containers, bastion/admin tooling, CI/CD runners | Restricted execution, workload identity boundaries, command telemetry, EDR/runtime controls, and tested response |
| **T1021 — Remote Services** | Lateral movement through administrative or remote-management paths | Movement from an exposed service or compromised operator endpoint | Admin plane, bastions, cluster nodes, support access | Network segmentation, just-in-time access, approved management paths, session recording, and alerting |
| **T1552 — Unsecured Credentials** | Discovery of secrets in configuration, images, logs, or repositories | Rapid reuse of exposed credentials to access tenants or cloud resources | CI/CD, container images, secrets stores, logs | Secret scanning, vault-backed retrieval, rotation, redaction, and proof that old credentials are unusable |
| **T1550 — Use Alternate Authentication Material** | Token/session reuse to bypass a password or MFA event | Theft and reuse of API keys, cookies, or refresh tokens | SaaS sessions, API tokens, workload credentials | Token binding/short lifetime, secure storage, revocation, replay detection, and forensic visibility |
| **T1562.001 — Impair Defenses: Disable or Modify Tools** | Suppression of logging or security tooling before collection or persistence | Disabling controls to prolong ransomware or data theft | Logging, monitoring, EDR/runtime controls, IAM | Immutable/remote logs, separation of admin duties, tamper alerts, protected telemetry, and recovery playbooks |
| **T1003 — OS Credential Dumping** | Potential credential access after workload or admin endpoint compromise | Credential theft for expansion or extortion | Approved host/workload boundary only; no uncontrolled production dumping | Credential isolation, hardened workloads, EDR detections, privileged access workstations, and a no-dump validation method |
| **T1567 — Exfiltration Over Web Service** | Stealthy extraction of engineering or tenant data through permitted services | Customer-data theft and monetization | API, storage, support export, and egress controls | Egress allowlisting, volume/behavior analytics, DLP where appropriate, export approvals, and tested containment |
| **T1486 — Data Encrypted for Impact** | Possible disruption pressure if access is retained | Material ransomware/extortion scenario against SaaS operations | Tenant data, backups, deployment and storage planes | Immutable isolated backups, key separation, recovery objectives, restore testing, and tenant communications plan |
| **BSI note — emerging TTP, exact wording and status to verify** | The italicized behavior is not claimed here because the source PDF is unavailable in this workspace | Same | Asset mapping depends on the note's exact behavior | Add a custom annotation only after confirming the note, technique definition, control owner, and validation evidence |

### Control and evidence model

For each contract-referenced technique, Helix should maintain four linked records: (1) the affected asset and tenant boundary, (2) the preventive control, (3) the detection/response control, and (4) evidence that the control works under an authorized exercise. A control marked “configured” without an alert, containment, or recovery test is not sufficient evidence of resilience. The assessment should distinguish platform-wide controls from tenant-specific controls and should record whether an observation applies to the sovereign infrastructure provider, Helix, or a customer-managed integration.

## Identified Findings

1. **F1 — Contractual technique coverage cannot yet be evidenced end to end (High / contractual).** The BSI requirement names adversary clusters and TTPs, but the exact source mapping and evidence plan must be reconciled to each ATT&CK technique before Helix can make a defensible resilience claim to BSI or DGA.
2. **F2 — Multi-tenant identity and authorization are the highest-consequence attack path (Critical / contractual).** T1078, T1550, and T1190 activity that crosses tenant boundaries could turn one compromised account or service into exposure of multiple aerospace customers. Helix needs tested tenant isolation, least privilege, token revocation, and detection evidence.
3. **F3 — Cloud and CI/CD secrets create a reusable bridge into the sovereign SaaS platform (High / contractual).** T1552 and T1059 paths can bypass the intended sovereignty and isolation design if secrets, runners, images, or workload identities are over-privileged.
4. **F4 — Defense impairment and recovery evidence are incomplete without an exercise (High / contractual).** T1562.001 and T1486 require more than prevention claims: Helix must demonstrate protected telemetry, isolated backups, and recovery within agreed objectives.
5. **F5 — Emerging BSI-note behavior requires a source-controlled extension (Open / contractual).** The italicized “emerging” TTP must be transcribed and mapped as a custom annotation if it is not present in the published ATT&CK version used for the engagement; it must not be silently forced into an unrelated technique.
