# Nexus Financial — Pre-Engagement Dossier

**Status:** Draft for lead-consultant review and client approval  
**Proposed assessment window:** Four weeks, with the exact calendar dates to be inserted in the signed statement of work  
**Critical gate:** No testing begins until every item in the Go / No-Go Checklist is complete.

## 1. Executive Summary

Vanguard will conduct an independent security assessment of Nexus Financial's payments platform and supporting technology before Nexus's Series B financing closes, with the objective of identifying exploitable risk without disrupting payment processing or mishandling personal data. The proposed engagement covers Nexus-owned web, mobile, API, cloud, administrative, VPN, and staging assets, with controlled production validation where separately approved; third-party Stripe and VerifyID infrastructure is excluded unless its owners provide written authorization. Nexus's CISO, James Okafor, is the operational sponsor, while CTO Thomas and CFO Maria must resolve the scope, risk tolerance, and board-authority questions before signature. Vanguard will use a staged, predominantly gray-box approach, report urgent issues immediately, and deliver a client-ready report in time for the investor meeting.

## 2. Scope Document

### In-scope assets

The following Nexus-owned or Nexus-controlled assets are proposed for inclusion, subject to the client completing the identifiers marked **TBD** in the signed scope schedule:

- **Core payments API:** the production API hostname(s), API gateway/WAF endpoints, and corresponding AWS resources in `eu-west-1` — exact hostnames, CIDRs, account IDs, and cluster/service identifiers: **TBD by Nexus**.
- **Customer-facing web application:** all production web hostnames, including the primary customer application hostname: **TBD by Nexus**.
- **Mobile applications:** Nexus's iOS and Android applications and their Nexus-controlled backend/API interactions. Test builds, package names, versions, and test accounts must be supplied before testing.
- **Backoffice administration:** `admin.nexus-financial.com`, including its Nexus-controlled application, authentication, roles, and approved test accounts.
- **AWS environment:** Nexus-owned AWS accounts, VPCs, security groups, IAM roles and policies, EKS clusters, RDS PostgreSQL instances, S3 buckets, load balancers, WAF rules, secrets/configuration, logging, and deployment resources in `eu-west-1`, limited to the accounts and resources identified in the signed schedule.
- **Staging environment:** the Nexus staging environment that mirrors production, including its application, API, EKS/RDS/S3 resources, and supporting cloud controls. Nexus must provide its hostname, account/resource identifiers, and confirmation that the environment contains no live customer or payment data.
- **Corporate remote-access environment:** the Nexus WireGuard VPN service and its associated Nexus-controlled authentication, configuration, and segmentation. The VPN endpoint hostname/IP, permitted test accounts, and explicitly permitted internal ranges must be listed before testing.
- **Internal network segments:** only the Nexus-owned internal ranges and systems listed in the signed schedule. The current summary does not provide IP ranges, so no internal address may be treated as in scope by inference.
- **Nexus-side payment and KYC integration components:** Nexus's API requests, validation logic, authentication, secrets handling, error handling, and data flows at the Nexus boundary for Stripe and VerifyID. This does not authorize requests against the providers' infrastructure or live customer transactions.

### Out-of-scope assets

- **VerifyID infrastructure, accounts, and API environment:** Nexus confirmed that it does not own or manage VerifyID infrastructure. Testing it without VerifyID's written authorization could be unauthorized access and could affect a critical regulatory service. Only Nexus-controlled integration code and a provider-approved sandbox may be tested.
- **Stripe infrastructure and payment gateway systems:** Stripe is a separate service provider. No live payment execution, gateway infrastructure testing, or provider-side exploitation is authorized. Nexus's payment integration may be tested with Stripe test mode and approved test transactions only.
- **Live customer transactions and irreversible financial actions:** production payments, refunds, payouts, account closures, fund transfers, and other transactions that could move money or affect customers are excluded unless a narrowly defined, separately approved canary procedure exists.
- **Production customer PII and payment data as a test dataset:** production data is not a source of evidence to collect. Where a production issue must be validated, Vanguard will use synthetic/test accounts or the minimum masked record necessary, subject to client approval.
- **Employee social engineering and phishing:** the current engagement should not include an all-employee campaign. It requires a separate social-engineering addendum, explicit executive approval, employee/privacy and HR coordination, approved templates, safety limits, and an emergency process.
- **Physical facilities, offices, employee home networks, personal devices, and personal accounts:** none is authorized by the current information.
- **Any cloud account, region, cluster, host, IP range, SaaS tenant, or third-party service not named in the signed scope schedule:** discovery does not expand scope.
- **Denial-of-service, stress/load testing, destructive actions, persistence, ransomware simulation, data deletion, and uncontrolled malware execution:** these create disproportionate availability and recovery risk and are not necessary for the proposed assessment.

### Scope boundaries and recommendations

#### VerifyID integration

**Recommendation:** Test only Nexus-controlled integration endpoints, request/response validation, authentication, authorization, logging, error handling, and data minimization. Use VerifyID's sandbox or test tenant if available. Do not send test data to VerifyID production or probe provider endpoints until VerifyID supplies written authorization and testing instructions; if that authorization is required, it must be attached to the scope schedule. This preserves the assessment's value while respecting third-party ownership and Nexus's GDPR obligations.

#### Production versus staging

**Recommendation:** Start with staging and use it for reconnaissance, automated checks, authenticated workflows, exploitation development, and any test that could affect availability. Staging must be confirmed free of live PII and production payment credentials. Move to production only for narrowly defined, non-destructive validation after Nexus gives written approval for each test class, provides test accounts and canary records, confirms backups/rollback, and confirms that the SOC, payment operations, Stripe test mode, and emergency contacts are ready. Production testing should normally occur during the agreed 09:00–18:00 CET window, with no testing during a payment peak, investor event, deployment freeze, or other blackout period.

#### Social engineering

**Recommendation:** Exclude the requested all-employee phishing campaign from this four-week assessment until the board-authority and risk-tolerance disagreement is resolved. If Nexus wants it later, use a separate addendum naming the target population, sender domains, content, landing pages, data collected, prohibited lures, safety exceptions, notification/stop contacts, and legal/HR/privacy approvals. A small, pre-approved pilot may be considered after the technical assessment, but “real attackers” is not sufficient authorization for an unbounded campaign.

#### Authorization and decision rights

James may be the operational sponsor, but his authority to authorize third-party access must be verified. Nexus must provide written authorization from the legally authorized signatory or governing body and written confirmation that the CTO and CFO have resolved scope, production risk, and any social-engineering decision. Their disagreement is a start blocker, not something Vanguard should resolve by choosing the more aggressive interpretation.

## 3. Rules of Engagement

### Testing windows and authorized hours

- Proposed duration: four weeks from the mutually signed start date; exact dates and blackout periods must be recorded in the statement of work.
- Staging and non-production testing: may occur during the agreed window, subject to notification and the client's change calendar.
- Production testing: 09:00–18:00 CET on approved business days only, with a written per-test approval for higher-risk actions. No testing during investor meetings, critical releases, settlement windows, or declared blackout periods.
- No overnight, weekend, or holiday production activity unless the client explicitly authorizes it in writing and confirms an on-call operations contact.
- Vanguard will not perform denial-of-service, load, destructive, persistence, or irreversible financial actions.

### Testing approach

The recommended model is **hybrid gray-box testing with limited white-box evidence**, not an unbounded black-box attack. Vanguard should receive architecture and data-flow diagrams, asset inventories, cloud account/resource identifiers, API documentation, test credentials for representative roles, and the relevant security configuration or IaC excerpts. Limited source or deployment review may be supplied for the payments API and integration components where Nexus wants faster, deeper coverage, but code review must be explicitly added to the signed scope. This approach gives meaningful coverage within four weeks, reduces disruptive discovery work, and lets Vanguard validate realistic authenticated attack paths without assuming permission to access unknown systems.

### Communication protocols

- **Operational contact:** James Okafor, CISO, is Vanguard's primary Nexus contact for scheduling, evidence, findings, and day-to-day decisions.
- **Technical authority:** Thomas, CTO, approves technical scope changes and remediation feasibility, but cannot unilaterally expand testing beyond the signed authorization.
- **Business/risk authority:** Maria, CFO, confirms blackout periods, business-impact tolerance, and investor-reporting constraints.
- **Vanguard contacts:** Sarah Chen is engagement lead and escalation owner; the assigned technical lead is the only person who directs testing activity.
- All scope changes, production approvals, and decisions affecting risk must be written in the approved project channel or email thread and recorded in the engagement log.
- A suspected critical vulnerability is reported immediately by phone and the secure channel, followed by a written summary. Routine findings remain in the working notes and interim updates until validated.
- A consultant who encounters uncertain ownership, unexpected sensitive data, service degradation, or an active compromise pauses the relevant activity and contacts Sarah and James.

### Emergency stop procedures

Testing stops immediately for any of the following: payment processing or material business-service degradation; unexpected data modification or deletion; access to live customer or payment data beyond the approved minimum; evidence of active compromise; unexpected access to a third-party system; a client stop request; a safety, legal, or law-enforcement concern; or a risk that cannot be controlled under the agreed method.

The person who observes the trigger stops the test action, preserves minimal volatile evidence where safe, and calls Sarah and James using the emergency contacts in the signed schedule. James or the designated Nexus incident commander may order a full engagement stop; Sarah may also stop Vanguard activity immediately. Resumption requires documented authorization, a risk decision, and updated instructions. Vanguard will not remediate, delete attacker artifacts, rotate credentials, or alter production systems unless specifically authorized and coordinated with Nexus's incident-response team.

### Data handling procedures

- Vanguard will request test accounts, synthetic records, masked data, and Stripe/VerifyID sandbox data wherever possible.
- If PII is encountered, the tester will stop at the minimum proof point, avoid bulk export, avoid unnecessary screenshots, and record only the fields needed to reproduce the finding.
- Evidence will be encrypted in transit and at rest, access-controlled to the named Vanguard engagement team, and stored only in Vanguard's approved secure workspace. It will not be placed in personal devices, public repositories, chat systems, or unapproved cloud storage.
- Reports will use redaction, hashing, masking, or synthetic examples. Raw PII will not appear in the executive report.
- Nexus will be notified promptly of any accidental access to PII, with the approximate records and fields involved, so Nexus can assess its GDPR obligations.
- Working evidence will be retained only for the period necessary to validate findings, produce the report, and complete the agreed retest; at closeout, Vanguard will securely delete it and provide confirmation, subject to any documented legal hold.
- Vanguard will not share Nexus data with investors, VerifyID, Stripe, or other third parties without Nexus's written authorization or a legal requirement.

### Incident discovery protocol

If Vanguard sees evidence that an external attacker is active, it will treat the matter as a potential client incident rather than as an ordinary finding. The tester will stop the affected exploit path, avoid tipping off or altering the attacker unless Nexus directs otherwise, preserve minimal relevant indicators, and immediately contact James and Sarah through the emergency channel. Nexus's incident-response team then controls containment, forensics, legal assessment, regulator notification, and communications; Vanguard may assist only under a separately confirmed instruction. The final report will distinguish evidence observed by Vanguard from assumptions and will not delay the emergency notification until the scheduled report.

## 4. Communication Plan

### Designated points of contact

| Function | Nexus | Vanguard | Purpose |
| --- | --- | --- | --- |
| Executive/operational sponsor | James Okafor, CISO | Sarah Chen, engagement lead | Daily decisions, approvals, escalation |
| Technical authority | Thomas, CTO | Assigned technical lead (name TBD) | Architecture, test access, technical scope |
| Business-risk authority | Maria, CFO | Sarah Chen | Blackouts, disruption tolerance, investor timing |
| Emergency incident contact | James plus Nexus incident commander (name/number TBD) | Sarah plus Vanguard on-call contact (number TBD) | Active compromise, outage, stop/resume |
| Privacy/legal contact | Nexus must name DPO or counsel before start | Vanguard engagement lead and privacy lead | PII, GDPR, third-party and disclosure questions |

Nexus must provide verified phone numbers, backup contacts, time-zone coverage, and an escalation order in the final Rules of Engagement. Vanguard will verify the identity and authority of anyone requesting scope changes or production activity.

### Reporting cadence

- **Pre-start:** kickoff, access validation, scope walk-through, and confirmation that the staging environment and test accounts are ready.
- **Twice weekly:** concise status update covering activities completed, coverage, blockers, risk observations, planned next steps, and any change requests.
- **Immediate:** critical exploitable findings, active compromise indicators, material data exposure, or service impact by phone and secure channel, followed by written confirmation.
- **Weekly:** stakeholder checkpoint with James, Thomas, Maria, and Sarah to reconcile technical coverage with business-risk and investor deadlines.
- **End of testing:** preliminary findings readout with validated critical/high issues, limitations, and remediation priorities.
- **Final deliverable:** executive summary, methodology and scope, risk-ranked findings, evidence, business impact, remediation plan, limitations, and a retest plan, delivered at least two weeks before the investor meeting if Nexus supplies access and approvals on time.

### Stakeholder management

The CTO's desire for realistic, comprehensive testing and the CFO's concern about disruption are both legitimate constraints. Vanguard should not accept “test everything” or “do nothing invasive” as a usable scope; Sarah should facilitate a decision meeting where the parties approve a risk-tiered plan: staging-first coverage, controlled production validation, explicit prohibited actions, and a separate decision on social engineering. The signed scope should identify who may approve changes and should record Maria's blackout periods and Thomas's technical priorities. If they cannot reach a documented decision, the affected workstream remains out of scope and the engagement does not start for that workstream.

### Secure communication channels

The parties will use Vanguard's approved encrypted project workspace for evidence, scope records, and report drafts; the exact platform and access list must be recorded at kickoff. Emergency calls use the verified contact numbers, with a follow-up message in the secure workspace. Email may be used for scheduling and non-sensitive confirmations only; PII, credentials, raw exploit output, and report evidence must not be sent in ordinary email or consumer messaging.

## 5. Risk Register

| ID | Engagement risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- | --- |
| R1 | Unverified authority or unresolved board/signatory approval could make otherwise authorized testing contractually or legally unauthorized. | Medium | Critical | Obtain signed authorization from a verified legal authority; attach the asset schedule and confirm CTO/CFO decision rights before start. |
| R2 | Production testing could interrupt payments or damage investor confidence during a critical business period. | Medium | Critical | Stage first; use non-destructive methods, test mode and canaries; define blackout periods, rate limits, rollback, monitoring, and written per-test production approval. |
| R3 | Testing or sending data to VerifyID or Stripe could access third-party infrastructure without permission or breach provider terms. | Medium | High | Exclude provider infrastructure; obtain provider authorization for any provider-side test; use Nexus-side validation and sandboxes only. |
| R4 | PII, bank details, or payment data could be exposed, retained, or copied during validation. | Medium | Critical | Use synthetic/masked data, minimum necessary evidence, encryption, access control, redaction, immediate notification, retention limits, and secure deletion. |
| R5 | Scope disagreement could cause missing coverage, unauthorized social engineering, or late decisions that consume the four-week window. | High | High | Hold a decision meeting; use a signed risk-tiered scope and change-control process; keep undecided workstreams out of scope. |
| R6 | A real attacker may be active in the environment, and Vanguard activity could alter evidence or interfere with response. | Medium | Critical | Define the incident protocol, emergency contacts, stop triggers, evidence limits, and handoff to Nexus's incident-response team before testing. |
| R7 | Incomplete asset inventory, cloud identifiers, IP ranges, or test credentials could create false assurance and delay delivery. | High | High | Make the asset schedule and access validation a start gate; track coverage and limitations in every status update and the final report. |
| R8 | A four-week timeline may be too short for “everything” across cloud, API, web, mobile, VPN, admin, and social engineering. | High | High | Prioritize payment-critical attack paths, use a staged approach, exclude undefined work, agree deliverables and assumptions, and offer a separately scheduled phase two. |
| R9 | Automated scanning or aggressive testing could trigger controls, exhaust resources, or create operational noise that hides a real incident. | Medium | High | Rate-limit activity, notify the SOC, use approved source addresses, stage automation, monitor health metrics, and prohibit uncontrolled load testing. |
| R10 | Findings may be miscommunicated to the board or investor before validation, creating legal or reputational harm. | Medium | High | Use a named communications process, validate findings before routine reporting, mark preliminary material clearly, and route external disclosures through Nexus legal/leadership. |

## 6. Go / No-Go Checklist

Testing begins only when every applicable item is checked **GO** and recorded in the engagement log. Any unchecked item is **NO-GO** for the affected activity; unresolved critical items are a NO-GO for the engagement as a whole.

- [ ] Signed statement of work, Rules of Engagement, data-processing terms, and asset schedule are complete.
- [ ] The signatory's legal authority to authorize third-party security testing is verified in writing; James's CISO title alone is not treated as sufficient proof.
- [ ] Nexus has documented agreement between the CTO and CFO on scope, production risk, blackout periods, disruption tolerance, and investor timing.
- [ ] James, Thomas, Maria, Nexus legal/privacy/DPO, SOC/incident response, payment operations, and the emergency incident commander are named with verified contact details.
- [ ] Every in-scope production hostname, IP/CIDR, AWS account/region, EKS cluster, RDS instance, S3 bucket, VPN endpoint/range, mobile build, and test environment is identified.
- [ ] Ownership and authorization for every target are confirmed; all unknown, third-party, and provider-owned assets are explicitly excluded or supported by written owner authorization.
- [ ] VerifyID's boundary is documented; no VerifyID production testing or test-data submission will occur without written VerifyID authorization and approved test instructions.
- [ ] Stripe's boundary is documented; only approved test-mode transactions and Nexus-controlled integration testing are permitted.
- [ ] Staging is confirmed available, isolated appropriately, free of live customer/payment data, and populated with approved test accounts.
- [ ] Production test classes have written approvals, rate limits, monitoring, rollback/backup confirmation, and explicit stop conditions.
- [ ] Social engineering is either excluded from this engagement or covered by a signed addendum with executive, HR/privacy, legal, safety, and emergency approvals.
- [ ] Test accounts, role matrix, API documentation, architecture/data-flow diagrams, cloud identifiers, and any agreed source/IaC/configuration artifacts are supplied securely.
- [ ] Vanguard has confirmed its testers, tools, source IPs, time windows, provider rules, and escalation coverage.
- [ ] Secure channels for evidence and reports are configured; access is limited to named personnel and credential exchange is tested.
- [ ] PII/payment-data handling, retention, breach notification, and secure deletion procedures are accepted by both parties.
- [ ] The active-compromise protocol, emergency stop process, and authority to pause/resume testing are understood in a live kickoff.
- [ ] The delivery schedule fits the investor deadline, including time for validation, client review, and final report production; any limitations are accepted in writing.

**Go decision:** Sarah and the authorized Nexus signatory record the final approval. If any required condition is not met, Vanguard does not begin the corresponding test and does not infer permission from discovery, verbal comments, or schedule pressure.
