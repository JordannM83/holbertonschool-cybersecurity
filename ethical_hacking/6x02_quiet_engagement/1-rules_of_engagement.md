# Rules of Engagement, Lumen Industrial Systems

## Engagement Metadata

| Field | Value |
| --- | --- |
| Client | Lumen Industrial Systems, Brno, Czech Republic |
| Consultant | Vanguard Security |
| Engagement reference | `VGS-LIS-PTES-2026-01` |
| Methodology | Penetration Testing Execution Standard (PTES), phases 1–7 |
| Assessment type | External black-box assessment with client-provided test accounts and a separately identified QA/demo environment where required |
| Proposed engagement window | 16 November 2026 08:00 CET through 27 November 2026 18:00 CET, subject to both signatures and target confirmation |
| Client signatory | Lumen CISO, or another officer expressly authorised by Lumen to approve security testing |
| Consultant signatory | Senior Partner, Vanguard Security |
| Working consultant | Junior consultant, Vanguard Security, under Sarah’s team-lead supervision |
| Evidence owner | Vanguard Security engagement lead until handover; Lumen CISO thereafter |

The dates and target identifiers in the signed statement of work and the final approved asset register supersede this draft if they differ. No testing starts until both parties have signed this document and Lumen has supplied the authoritative domain names, IP addresses, API base URLs, administrative-panel URLs, and demo gateway/MQTT identifiers.

## Scope

### In Scope

Testing is authorised only against Lumen-controlled assets that appear in the signed asset register. The in-scope classes are:

- Lumen’s cloud-hosted production and non-production platform endpoints that Lumen owns or is contractually authorised to test, including the externally reachable web application and supporting public services named in the asset register.
- Lumen’s public API, including documented and discovered API routes on the approved API hostnames, using only the supplied test accounts and data. API discovery may include unauthenticated and authenticated routes, but must remain within the approved hostnames and rate limits.
- Lumen’s internal administrative panel only when it is exposed through the approved assessment access path, VPN, allow-listed source address, or other access mechanism documented by Lumen. Administrative testing is limited to test accounts unless the CISO gives written approval for a specific privileged test.
- The Lumen-owned demo/QA edge gateway identified by hostname, IP address, serial or asset identifier in the signed register.
- The Lumen-owned demo/QA MQTT broker identified in the signed register, including its approved listener, TLS endpoint, test topics, and test credentials. Testing must use test topics and must not publish operational commands or messages to customer-connected topics.
- Publicly available intelligence about Lumen’s own corporate presence, including Lumen-owned domains, DNS records, certificate-transparency records, public web pages, public documentation, public code or package repositories, public job postings, and public employee, partner, or customer references. Collection is limited to information relevant to the assessment and does not authorise pretexting, credential attacks, or contact with employees or third parties.
- Passive and low-impact active enumeration needed to confirm the approved perimeter, such as DNS lookups, HTTP/TLS metadata collection, web crawling with a declared user agent, and conservative service/version probing. Active enumeration is permitted only for confirmed in-scope names and addresses.

The asset register is the controlling boundary. A hostname that resolves to a Lumen-branded service is not automatically in scope, and technical reachability is not evidence of legal authority.

### Out of Scope

- Edge gateways, sensors, PLCs, production networks, and other equipment deployed at Lumen’s industrial customers’ premises. Lumen does not own or control those assets and has stated that it has no legal authority to authorise testing against them.
- Any industrial customer’s cloud account, tenant, network, domain, IP address, gateway, sensor, MQTT broker, VPN, or other infrastructure, even when it is reachable through Lumen’s platform or appears in DNS, certificates, telemetry, documentation, or enumeration results. Discovery of such an asset is recorded as an observation and testing stops for that asset.
- Customer production data, customer credentials, customer tenants, customer topics, and customer operational commands. The engagement uses Lumen-supplied test tenants, test records, and test topics only.
- Third-party SaaS, cloud, CDN, DNS, hosting, monitoring, identity, payment, messaging, repository, or security-provider infrastructure unless the provider and the exact asset are listed in the signed asset register with written authorization from the provider or an authorization basis accepted by the provider.
- Lumen employee devices, home networks, personal accounts, personal repositories, personal email, and social-media accounts. Public professional information may be collected without interaction; employees must not be phished, called, messaged, impersonated, or tested.
- Physical security, social engineering, denial-of-service, stress/load testing, destructive testing, persistence, ransomware simulation, malware deployment, supply-chain compromise, and tests that could interrupt industrial monitoring.
- Any IP address, hostname, URL, MQTT topic, certificate subject, cloud resource, or network route not explicitly added to the signed asset register. Scope expansion requires written approval from the Lumen CISO and the Vanguard engagement lead before testing.

The exclusions protect third-party property and industrial safety. Lumen’s commercial relationship with a customer does not transfer authority to test that customer’s systems; a reachable asset remains out of scope unless its owner has independently authorised the work.

## Testing Window

- Active testing: Monday through Friday, 08:00–18:00 Central European Time (CET, Europe/Prague), during the approved engagement dates.
- Passive collection and report preparation: may occur outside the active window, but no new active requests, authentication attempts, exploitation, or MQTT publication may occur outside it without written approval.
- Blackout periods: all weekends; Czech public holidays; any Lumen change freeze; customer production releases; incident-response activity; and any period that Lumen’s CISO, on-call contact, or hosting provider declares unsafe. Lumen must notify Vanguard of planned freezes as soon as known.
- The assessment is not a load test. Requests are rate-limited, concurrency is conservative, and testing pauses if latency, error rate, resource use, queue depth, MQTT delivery, or monitoring alerts materially change from the agreed baseline.
- Any exception to the hours, blackout periods, rate limits, or test method requires written approval in the action log from the Lumen CISO or delegate and the Vanguard engagement lead.

## Communication and Escalation

Before testing begins, Lumen will fill in and approve the names, telephone numbers, and email addresses below. A role title alone is not an emergency contact.

| Role | Contact | Responsibility | Expected response |
| --- | --- | --- | --- |
| Primary client contact | Lumen CISO or named security lead, supplied in the signed contact sheet | Scope decisions, approvals, findings, and stop/restart authority | Acknowledge normal queries within 4 business hours; urgent events within 30 minutes |
| Secondary client contact | Lumen engineering/on-call lead, supplied in the signed contact sheet | Technical coordination, maintenance windows, service-impact triage | Urgent events within 15 minutes; normal queries within 1 business day |
| Client executive escalation | Lumen CTO or delegated executive | Material impact, suspected compromise, customer notification, or unresolved scope issue | Contact immediately for a critical event; response target 30 minutes |
| Consultant contact | Sarah, Vanguard Security team lead, with contact details in the signed contact sheet | Daily supervision, operational decisions, and consultant escalation | Available during the active window; urgent escalation immediately |
| Consultant approval contact | Vanguard Security senior partner | Contract, legal, material-risk, and report-signature decisions | Same business day; immediately for a stop condition |

The primary channel is the client-approved encrypted collaboration channel or ticketing system identified in the contact sheet. Email is used for formal approvals and scope changes. Telephone is used for urgent stop conditions, followed by a written record. The action log records the time, participants, decision, and resulting authorization. If a contact cannot be reached, Vanguard does not interpret silence as consent; testing pauses at the affected boundary.

## Authorised Tools, Forbidden Tools

Authorised tools must be used conservatively, from Vanguard-controlled systems, with output retained as engagement evidence where relevant. The list is illustrative but bounded by the following purposes:

- DNS and certificate-transparency lookups, WHOIS/RDAP where lawful, passive search, and public-web review for reconnaissance.
- Standard HTTP clients, browser developer tools, intercepting proxy, web crawler, API client, and non-destructive content discovery against approved web/API hosts.
- Conservative TCP/TLS/service discovery and version detection against confirmed in-scope addresses, with an approved source address and rate limit.
- MQTT client tooling against the approved demo broker, using only Lumen test credentials and test topics.
- Hand-written scripts and small utilities for reproducible requests, evidence collection, parsing, and validation, reviewed by the team lead before use against the target.
- Vulnerability scanners only with safe checks, bounded scope, conservative concurrency, and the relevant scan configuration preserved in evidence.
- Cryptographic, hashing, screenshot, and timestamping utilities needed to preserve evidence and verify integrity.

The following are forbidden unless this RoE is amended in writing:

- Metasploit for the initial foothold. The polyglot upload test, if authorised by the asset register and client, must use a hand-written or publicly documented technique whose source, payload, hash, and exact actions are recorded in the action log. Metasploit may be used only for a separately justified post-exploitation utility task after written approval.
- Any exploit, payload, scanner mode, or script intended to cause denial of service, destructive change, persistence, ransomware behavior, mass data access, or uncontrolled propagation.
- Phishing, credential harvesting, password spraying, brute force, social engineering, physical intrusion, malware, reverse shells that are not explicitly approved, and use of real customer or employee credentials.
- Testing customer-controlled assets, broad Internet scanning, cloud-control-plane actions, or third-party service testing outside the signed asset register.
- Uploading client data or evidence to public services, generative tools, paste sites, personal storage, or unapproved SaaS.

## Stop Conditions

Testing halts immediately, the affected activity is not resumed, and the primary and secondary client contacts are notified when any of the following occurs:

- A request, route, identity, tenant, topic, IP address, or hostname appears to belong to an industrial customer or another excluded third party.
- The consultant cannot establish that the target is in the signed asset register, or a scope boundary becomes ambiguous.
- A production, monitoring, authentication, API, gateway, broker, or customer-facing service shows material degradation, unexpected errors, instability, queue growth, data corruption, or safety-relevant behavior.
- Testing could send an operational command, modify industrial telemetry, publish to a customer topic, change production configuration, or access real customer data.
- Evidence suggests a live compromise, active incident, credential exposure, secret leakage, or unauthorized access not created by the engagement.
- A stop request is received from Lumen, a hosting provider, Sarah, the Vanguard engagement lead, or the senior partner.
- A rate limit, maintenance window, blackout period, emergency procedure, or technical control is exceeded or unavailable.
- The consultant loses the approved secure access path, test account, logging capability, or ability to attribute an action.

The consultant preserves the minimum evidence needed to explain the trigger, avoids further exploration, records the event in the action log, and awaits a written restart decision. Restart requires confirmation of scope, service health, and authorization by the Lumen CISO or delegate and the Vanguard engagement lead.

## Data Handling

- Vanguard collects the minimum data necessary to validate and explain a finding. Test data will be synthetic or Lumen-provided test data wherever possible.
- Real personal data, customer data, credentials, tokens, private keys, secrets, or industrial telemetry encountered accidentally are not copied beyond what is necessary to prove exposure. The consultant stops access, records the location and type of exposure without reproducing the value, and reports it to the primary contact through the approved encrypted channel.
- Evidence is stored only in Vanguard’s access-controlled engagement repository, encrypted in transit and at rest, with access limited to the assigned consultant, Sarah, the engagement lead, and authorized report reviewers. Evidence is labeled with the engagement reference and sensitivity.
- Secrets are redacted from screenshots, notes, reports, and tickets. Passwords and tokens used for testing are revoked or rotated by Lumen after testing; Vanguard does not retain usable credentials after handover.
- Vanguard retains the final report, action log, scope approvals, and material evidence for 12 months after final delivery to support audit questions and contractual dispute resolution, unless the signed contract requires a shorter period. Lumen may request earlier deletion of copies that are not required for legal, contractual, or audit obligations.
- At the end of the retention period, Vanguard securely deletes working copies and destroys temporary media, subject to a documented deletion confirmation. Lumen remains responsible for retention of the final deliverables in its own compliance records.

## Post-Engagement Obligations

- Vanguard provides an initial critical/urgent notification without waiting for the final report, normally within one business day of confirmation and immediately where a stop condition or active compromise is involved.
- Vanguard delivers a findings readout and draft report within five business days after the active testing window closes. The report includes scope, limitations, methodology, evidence references, severity, business and NIS2 relevance, remediation advice, and a mapping back to the action log.
- Lumen receives three business days to identify factual errors or provide remediation context. Lumen may comment on accuracy and context; it may not require Vanguard to omit, downgrade, or mischaracterize a confirmed finding. Any disagreement is recorded in the final report.
- Vanguard delivers the signed final report within ten business days after the readout, or on the alternative date agreed in writing. The report is suitable for inclusion in Lumen’s NIS2 conformity packet and identifies the limits of the test so that it is not represented as assurance over excluded customer infrastructure.
- Vanguard provides one audit-support window of up to four hours during the 60 days after final delivery for clarification of methodology, evidence references, scope, and findings. New testing, remediation validation, or customer-specific attestations require a separate written authorization.
- Vanguard performs no remediation or configuration change unless separately authorized. Lumen owns remediation, customer communication, regulatory notification, and decisions about incident reporting. Vanguard will promptly provide factual assistance if requested and authorized.

## Signatures

Signing confirms that the parties understand and approve the boundary, hours, methods, contacts, stop conditions, evidence handling, and post-engagement obligations above.

**For Lumen Industrial Systems**

Name: ____________________________________  
Title: _____________________________________  
Signature: _________________________________  
Date (CET): ________________________________

**For Vanguard Security**

Name: ____________________________________  
Title: Senior Partner  
Signature: _________________________________  
Date (CET): ________________________________

