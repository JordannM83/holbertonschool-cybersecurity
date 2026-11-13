# Penetration Test Report, Lumen Industrial Systems

**Engagement reference:** `VGS-LIS-PTES-2026-01`  
**Reporting period:** 13 November 2026 readiness review; proposed active window 16–27 November 2026 did not commence  
**Prepared by:** Junior Consultant, Vanguard Security  
**Distribution:** Lumen CISO and approved downstream NIS2 conformity-packet recipients  
**Report status:** Incomplete engagement — no security assurance claim

## 1. Executive Summary

Vanguard Security did not perform an active penetration test of Lumen Industrial Systems during the recorded reporting period. The engagement was stopped at authorization and target-confirmation readiness because Lumen’s signed asset register, target hostnames and addresses, approved access path, test credentials, test tenants, and MQTT topics were not available. Consequently, no web, API, SSH, MQTT, authentication, file-upload, exploitation, pivot, impact, or cleanup activity was performed; no vulnerability can be confirmed or ruled out; and no CVSS-rated security finding is issued. This document must not be used as evidence that Lumen’s controls passed testing or as evidence of NIS2 conformity. It is evidence that the engagement boundary was checked and that Vanguard did not test customer-owned industrial infrastructure without authority. Before the report can support a conformity packet, Lumen must complete the asset register and contacts, authorize the active window, supply safe test access, and commission a new execution period whose evidence is recorded in the action log.

## 2. Scope and Methodology

The governing Rules of Engagement are in `1-rules_of_engagement.md`. The intended scope was Lumen-controlled infrastructure only: the cloud-hosted platform, public REST API, internal administrative panel, Lumen-owned demo/QA edge gateway, and Lumen-owned demo/QA MQTT broker. Publicly available intelligence about Lumen’s own corporate presence was also permitted. Industrial customer gateways, sensors, PLCs, production networks, customer tenants, customer topics, third-party infrastructure, employee devices and accounts, social engineering, denial-of-service, destructive testing, and any asset absent from the signed register were excluded.

The intended assessment was a PTES engagement with conservative active testing during Monday–Friday, 08:00–18:00 Europe/Prague time, subject to signed authorization, blackout periods, rate limits, and immediate stop conditions. The planned technical work included low-impact HTTP/TLS and service enumeration, authenticated testing with Lumen test accounts, controlled file-upload validation, SSH service identification on the demo gateway, and access-control checks on test MQTT topics. The RoE prohibited Metasploit for the initial foothold and prohibited customer or industrial operational activity.

The controlling evidence is `3-actions_log.md`. Its Phase 4 entries record that the five surface classes were known conceptually but that no concrete target identifiers were supplied. Its Phase 5 entries record review of OWASP file-upload guidance and a proposed safe test design, but no request, payload delivery, execution, shell, pivot, or impact action. Its Phase 6 entries record that no artifact was created and that no cleanup command was required. This report makes no claim beyond that evidence.

## 3. PTES Phase Summary

**Phase 1 — Pre-engagement interactions.** The engagement purpose, client context, intended PTES methodology, business deadline, and industrial-customer boundary were documented. The RoE specified the parties, operating hours, communication expectations, forbidden activity, stop conditions, data handling, and post-engagement obligations. The remaining prerequisite was an executed contact sheet and signed asset register containing concrete targets.

**Phase 2 — Intelligence gathering.** The intended collection covered Lumen-owned web, DNS, certificate, marketing, documentation, repository, job-posting, employee-reference, partner-reference, and customer-reference surfaces. The actual record contains no confirmed domain, IP address, URL, public API base, gateway address, or broker listener. Active reconnaissance therefore did not begin. No customer-owned system was probed.

**Phase 3 — Threat modelling.** The threat model identified plausible risks for the named Lumen asset classes, including tenant-isolation failure, public API compromise, administrative-plane compromise, unsafe file upload, gateway takeover, MQTT authorization failure, and telemetry tampering. Those are prioritization hypotheses, not findings. The model explicitly required later validation against surfaced assets and did not authorize testing of customer infrastructure.

**Phase 4 — Vulnerability analysis.** The plan covered the five intended surfaces: customer-facing portal, internal admin panel, public REST API, demo SSH gateway, and demo MQTT broker. The action log records only safe enumeration planning and the absence of target prerequisites. No banner, route, software version, configuration, authentication response, vulnerability, or flag was observed.

**Phase 5 — Exploitation.** The expected exercise path was a controlled polyglot file-upload test against the admin panel, followed by an authorized pivot and bounded impact demonstration. OWASP guidance was reviewed for extension, MIME, signature, filename, storage, and execution controls. No payload was delivered, no bypass was observed, no Metasploit module was used, and no foothold or pivot existed.

**Phase 6 — Post-exploitation.** No post-exploitation enumeration occurred because there was no session or host access. No data classes, customer identities, internal functions, credentials, broker topics, or IoT management functions were reached. No files, accounts, scheduled tasks, configurations, or broker messages were created, so the action log records a negative cleanup verification rather than a cleanup command.

**Phase 7 — Reporting.** This report converts the action log and RoE into a bounded status document. It records the absence of test evidence, prevents the result from being represented as a pass, and identifies the inputs required to restart the engagement. A signed final assurance report requires a completed active window and evidence-based findings or tested controls.

## 4. Findings

### 4.1 Technical assessment could not validate the in-scope controls — Severity: High (assurance gap, not a confirmed software vulnerability)

- **Technical description:** No target was contacted and no application, host, API, SSH service, MQTT broker, upload path, authentication flow, or internal function was tested. Identification and exploitability therefore remain unknown. This is a technical assessment/evidence failure, not a claim that a specific Lumen component is exploitable.
- **CVSS environmental score:** Not applicable; no confirmed vulnerability exists to score. No CVSS vector is issued because assigning one to an untested hypothesis would create false precision. The severity is an engagement and assurance priority, not a CVSS severity.
- **NIS2 article relevance:** The absence of test evidence is relevant to the evidentiary aspect of Article 21 risk-management measures, but it is not itself a claim that Article 21 controls failed. Article 23 incident-reporting obligations cannot be assessed because no incident or compromise was observed.
- **Business impact for Lumen:** Lumen cannot use this document to demonstrate that its platform, API, administrative panel, demo gateway, or MQTT broker resisted testing. Sending it to customer auditors as a completed pentest report would overstate the work and could jeopardize the renewals it was intended to support.
- **Remediation:** Complete and sign the asset register; provide the concrete target identifiers, approved source address, test accounts, test tenants, broker topics, emergency contacts, and blackout schedule; then authorize a new active window. Preserve the action log and require every test result to identify the exact target and evidence reference.

### 4.2 Engagement authorization and evidence package incomplete — Severity: High (operational risk, not a confirmed software vulnerability)

- **Technical description:** The RoE names asset classes but does not contain the concrete identifiers required to distinguish Lumen assets from reachable customer or third-party assets. The action log records the missing admin-panel URL, API base URL, gateway address, broker address, credentials, and safe validation endpoints.
- **CVSS environmental score:** Not applicable; this is a delivery and authorization gap, not a confirmed exploitable software vulnerability, so no CVSS vector is defensible.
- **NIS2 article relevance:** The gap weakens Lumen’s ability to demonstrate a repeatable, risk-based cybersecurity practice under Article 21. It does not establish an Article 23 incident-reporting event.
- **Business impact for Lumen:** Testing delay directly threatens the eight-week renewal and financing timetable. More importantly, testing without these details could cross into customer-owned infrastructure, creating legal, contractual, and auditor-trust consequences.
- **Remediation:** Treat the signed asset register as a release gate. For each asset, record owner, hostname/IP, environment, ports, tenant, test account, data classification, allowed actions, rate limit, monitoring contact, and stop/restart authority. Do not accept technical reachability as authorization.

No Critical, High, Medium, or Low technical vulnerability is reported because no technical result supports one. The threat model’s hypotheses must not be copied into a conformity packet as findings.

## 5. Exploitation Narrative

There is no exploitation chain to narrate. At 10:15 UTC, the action log records a review of the requested polyglot-upload path and explicitly records that no payload was built, transmitted, or executed. At 10:21 UTC, OWASP guidance was documented as the future test basis; at 10:23 UTC, a benign controlled test design was recorded as a plan only. The log contains no upload request, HTTP response, stored-file URL, execution signal, process identity, shell, credential, token, lateral request, MQTT publication, or impact data.

The absence of a foothold is an engagement state, not a security conclusion. It does not mean the upload control is secure, that the admin panel is not vulnerable, or that the IoT management plane is protected. It means the required evidence was not obtained. Likewise, the Phase 6 entries do not claim that sensitive data is absent; they record only that Vanguard did not access it and did not create artifacts requiring removal.

## 6. Recommendations

**Immediate priorities:**

1. Freeze the conformity-packet claim until an active, signed, target-specific assessment is completed.
2. Complete the asset register and contact sheet, including exact targets, ownership, test identities, test tenants, MQTT topics, source allow-list, rate limits, and stop conditions.
3. Schedule the active window with Lumen operations and confirm that the demo gateway and broker are isolated from customer environments.
4. Provide a clean evidence workspace and require UTC timestamps, request/response references, hashes, screenshots, and command results for every material action.

**Technical priorities for the restarted assessment:**

1. Validate tenant isolation and privileged administrative authorization using separate Lumen test identities.
2. Test the upload workflow with harmless files and verify extension, MIME, signature, filename, storage, authorization, and non-execution controls before any approved exploit validation.
3. Validate SSH hardening and MQTT authentication/authorization only on the Lumen demo assets and test topics.
4. Review secrets exposure in API responses and application configuration without copying production credentials; rotate any test secret after use.

**Long-term posture:** maintain a versioned asset inventory, repeat scoped external testing after material changes, separate customer and demo trust boundaries, enforce least privilege and short-lived credentials, store uploads outside executable webroots, and retain an immutable action log with remediation and retest evidence.

## 7. Limitations and Uncertainty

The active testing window did not commence. No DNS lookup, HTTP request, TLS handshake, port scan, SSH connection, MQTT connection, login, upload, exploit, pivot, data query, or cleanup command was executed against Lumen. The report therefore cannot assess patch status, authentication, authorization, tenant isolation, file-upload behavior, host configuration, broker ACLs, monitoring, detection, resilience, or impact.

The threat model and RoE describe intended asset classes, not confirmed live assets. The report does not validate that the five surfaces exist at particular addresses, that they are Lumen-owned, or that they are isolated from customer environments. No employees, partners, customers, or third parties were contacted or tested. No customer-owned gateway, sensor, PLC, network, tenant, or broker was probed.

The report was prepared from the repository deliverables and action log available on 13 November 2026. It must be superseded by a new report after execution. A future report should preserve this report as a record of the cancelled or incomplete attempt rather than silently rewriting the history.

## 8. Appendices

### A. Sourced findings

No technical vulnerability was confirmed. The operational risk and required remediation in Section 4 are sourced to the missing-target and no-action entries in `3-actions_log.md`, especially the Phase 4 entries at 10:00–10:10 UTC and the Phase 5/6 entries at 10:15–10:29 UTC.

The file-upload test basis is the OWASP File Upload Cheat Sheet, which recommends defense in depth: allowlisted extensions, validation of file type rather than trusting the user-supplied Content-Type, signature checks, safe generated filenames, authorization, size limits, storage outside the webroot, and controls preventing uploaded content from executing. It also identifies double extensions, null-byte handling, case manipulation, alternate extensions, and unsafe retrieval as areas requiring careful validation. These are test considerations, not Lumen findings.

### B. Action log excerpt

The complete source of truth is `3-actions_log.md`. The relevant sequence is:

| Timestamp (UTC) | Phase | Recorded result |
| --- | --- | --- |
| 2026-11-13T10:00:00Z | 4 | No concrete asset identifiers; active testing blocked. |
| 2026-11-13T10:15:00Z | 5 | No polyglot built, transmitted, or executed; no foothold. |
| 2026-11-13T10:21:00Z | 5 | OWASP file-upload guidance reviewed; no bypass observed. |
| 2026-11-13T10:23:00Z | 5 | Controlled test design documented; no request sent. |
| 2026-11-13T10:25:00Z | 6 | No impact enumeration; no NIS2 impact fact asserted. |
| 2026-11-13T10:27:00Z | 6 | No artifacts created; no cleanup command required. |

### C. Framework references

- Penetration Testing Execution Standard, main page and technical guidelines: the seven-phase methodology used for the engagement structure.
- Directive (EU) 2022/2555 (NIS2), Articles 21 and 23: risk-management measures and incident-reporting context.
- OWASP, [File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html): file-upload threat and defense-in-depth reference.
- `1-rules_of_engagement.md`: controlling scope, authorization, communications, stop conditions, data handling, and post-engagement obligations.
- `2-threat_model.md`: hypotheses and prioritization context; not evidence of confirmed vulnerabilities.
- `3-actions_log.md`: chronological record of the work actually performed.

