# Sundara Lifestyle — Threat Model

## Framework Declaration

**PASTA (Process for Attack Simulation and Threat Analysis)**

## Rationale

PASTA is the right lens for Sundara because the engagement is a board-level decision about whether to delay the European launch for six months or proceed while the IPO timetable continues, rather than a purely technical inventory exercise. The business context connects the prior loyalty-data breach, the aggressive Germany/France/Netherlands launch, and Sundara's marketing partnerships to material reputation and revenue consequences. The mobile architecture contains 12 million loyalty accounts, integrated payment, geolocation, AI recommendations, and cross-border reservations, while the Rules of Engagement explicitly require cross-jurisdictional treatment of Singapore PDPA and EU GDPR. PASTA's business-objective, data-flow, and attack-simulation stages can therefore translate technical attack paths into residual launch risk for directors who need to choose a release posture.

## Framework Selection Feedback

PASTA's strength for Sundara is that it connects an attack against a loyalty or reservation data flow to the board's actual decision: whether the EU launch can proceed without repeating the competitor's credibility-damaging breach. Its trade-off is that PASTA is more time- and evidence-intensive than a compact architecture checklist, and it will not by itself provide the detailed control-by-control decomposition that a later STRIDE review or technical test may add.

## Threat Model

### Stage I — Define business objectives

Sundara wants to launch in Germany, France, and the Netherlands while protecting the value of 12 million loyalty accounts, maintaining integrated payment and reservation services, meeting Singapore PDPA obligations, and establishing a defensible GDPR posture for EU expansion. The decision is binary in business terms—delay for hardening or proceed on schedule—but the security decision should be expressed as release gates. A proceed decision is defensible only if the highest-impact customer-account, payment, profiling, and cross-border transfer risks have effective controls and tested response capacity. A delay is justified if a material attack path remains exploitable or if Sundara cannot demonstrate who controls personal data as it crosses jurisdictions and partners.

### Stage II — Define the technical scope

The modeled first-party perimeter contains:

- Sundara's iOS and Android mobile applications and their application interfaces.
- The loyalty-account lifecycle, authentication, authorization, profile, and loyalty-data services represented in the mobile architecture.
- Sundara-controlled payment integration boundaries, including request construction, token handling, callback validation, and error/logging behavior. The payment provider's infrastructure is an external dependency, not a Sundara-owned target.
- Sundara-controlled geolocation collection, storage, access, and use by AI recommendation services.
- Sundara-controlled cross-border reservations functionality, its APIs, booking records, and country/market routing logic.
- Sundara-controlled integrations and data-sharing interfaces with marketing partners, limited to the Sundara side of each boundary and the contractual/data-governance controls governing the exchange.

The POS hardware and software are not built or operated by Sundara and are excluded from the threat model. Third-party provider infrastructure, partner systems, app-store infrastructure, and networks outside Sundara's control are also not directly modeled as Sundara assets; their interaction with Sundara is modeled as a dependency, trust boundary, and contractual risk.

### Stage III — Application decomposition and data-flow inventory

| Business/data flow | First-party responsibility | Cross-border and regulatory question |
| --- | --- | --- |
| Loyalty account registration, login, and profile access | Identity, session, authorization, account recovery, and data minimization in Sundara services and apps | Which entity determines the purpose of processing, and can an attacker take over an account or enumerate profiles across markets? |
| Mobile app to payment integration | Sundara's payment request, token/callback handling, secrets, and logs | Does Sundara avoid unnecessary payment data retention, and are payment callbacks authenticated and bound to the right customer/order? |
| Mobile app to geolocation and AI recommendation services | Collection consent/notice, purpose limitation, retention, model inputs, and access control | Is precise location transferred or reused across markets without an appropriate notice, legal basis, or transfer mechanism? |
| Cross-border reservation creation and retrieval | Sundara's reservation API, identity binding, market routing, booking records, and cancellation/refund logic | Can a user or partner access another market's reservation data, and where are records stored or processed? |
| Sundara to marketing partners | Partner selection, data minimization, API authentication, contract, monitoring, and deletion/return controls | Does a partner receive more loyalty, location, or behavioral data than necessary, and can Sundara demonstrate onward-transfer and deletion controls? |
| EU user or reservation data to Singapore/Sundara services | Sundara's transfer mapping, access controls, processor/controller decisions, and response process | GDPR transfer requirements and Singapore PDPA transfer-limitation obligations must be addressed together rather than treating one as a substitute for the other. |

### Stage IV — Threat analysis

The threat intelligence briefing's retail-sector skimmer and loyalty-data activity makes account takeover, payment-boundary abuse, and loyalty-data theft the primary external threat themes. The competitor breach precedent increases the business impact of a confidentiality failure even if payment numbers are tokenized. The following threat statements are prioritized by their ability to force a launch delay, trigger regulatory response, or undermine the IPO narrative:

1. **Loyalty account takeover and mass profile access:** credential stuffing, weak recovery, token theft, or authorization flaws could expose a large account population and enable fraud or reputational damage.
2. **Reservation authorization failure:** an IDOR or market/tenant confusion could let one customer, partner, or compromised session read or alter another country's reservations.
3. **Payment callback or integration abuse:** forged callbacks, replayed payment states, or leaked integration secrets could create fraudulent confirmations, refunds, or order manipulation without requiring compromise of the payment provider.
4. **Location and recommendation profiling exposure:** excessive collection, insecure storage, model/debug leakage, or partner reuse could reveal sensitive movement or preference patterns.
5. **Marketing-partner overreach:** a compromised or poorly governed partner connection could receive excessive loyalty data or use it for an undisclosed purpose. This is a Sundara governance and boundary risk; partner-owned infrastructure is not assumed to be directly testable.
6. **Cross-border transfer and deletion failure:** EU personal data could be sent to Singapore or another market without an appropriate documented transfer basis, safeguards, retention control, or data-subject process, creating simultaneous operational, regulatory, and launch risk under GDPR and PDPA.
7. **Mobile/API secret and supply-chain exposure:** reverse-engineerable secrets, insecure local storage, weak certificate validation, or an unprotected API could turn a mobile compromise into a large-scale backend attack.

### Stage V — Vulnerability and control analysis

| Threat | Control questions and validation focus | Launch significance |
| --- | --- | --- |
| Account takeover / loyalty theft | Phishing-resistant or risk-based authentication where appropriate, rate limits, credential-stuffing detection, recovery binding, session revocation, object-level authorization, and bulk-access monitoring | A broad loyalty breach repeats the competitor precedent and can undermine EU launch credibility. |
| Reservation cross-tenant access | Server-side authorization on every object and operation, explicit market/tenant binding, negative tests across countries, audit trails, and safe cancellation/refund rules | A cross-market exposure is both a customer harm and a visible failure of expansion readiness. |
| Payment integration abuse | Signed/verified callbacks, nonce or replay protection, server-side amount/order binding, secret vaulting and rotation, test-mode validation, and redacted logs | Fraud or false payment state can cause direct financial loss and launch disruption. |
| Location/AI exposure | Purpose and retention inventory, consent/notice controls, encryption, role separation, model/data isolation, deletion handling, and partner restrictions | Geolocation is sensitive personal data in context; uncontrolled reuse increases GDPR/PDPA and trust risk. |
| Partner data overreach | Data minimization, scoped tokens, contract and processor/controller roles, subprocessor/onward-transfer review, monitoring, revocation, and deletion attestation | Sundara may remain accountable for a boundary it does not fully operate. |
| Cross-border governance failure | Records of processing, transfer mapping, safeguards, retention/deletion, incident routes, and rights-request ownership for EU and Singapore flows | An unresolved transfer or rights process should be a launch gate, not a post-launch action item. |

### Stage VI — Attack simulation plan

Subject to the signed Rules of Engagement, Vanguard should simulate the highest-value paths in a staged and non-destructive manner:

- Begin with test loyalty accounts and test reservations, then validate authorization across markets and roles without bulk-exporting real customer data.
- Exercise credential-stuffing resistance, recovery, session and token boundaries, and API object authorization using approved accounts and rate limits.
- Validate payment callback and reservation-state controls in provider-approved test mode; do not test provider infrastructure or execute live financial transactions.
- Test mobile/API secret exposure and transport/session controls using approved builds and backend endpoints.
- Review the Sundara side of marketing and cross-border integrations, requesting partner authorization separately where a test would cross into partner infrastructure.
- Use canary data to trace location, recommendation, loyalty, and reservation records through Singapore, EU, and partner paths; stop if real PII appears beyond the minimum proof point.

### Stage VII — Risk analysis and board decision

| Decision gate | Proceed only if | Delay if |
| --- | --- | --- |
| Customer and loyalty trust | High-volume account takeover and object-authorization paths are controlled, monitored, and retested | A scalable path to loyalty profiles or cross-market reservations remains exploitable |
| Payment and reservation integrity | Payment callbacks, booking state, cancellation, and refund workflows are server-side validated and tested safely | An attacker can forge state, replay a transaction, or alter another customer's reservation |
| Privacy and cross-border governance | Sundara can document GDPR and PDPA roles, notices/bases, transfer safeguards, retention, deletion, and response ownership | EU-to-Singapore/partner flows or data-purpose boundaries remain undocumented or uncontrolled |
| Detection and response | Sundara can detect mass access, partner misuse, suspicious geolocation/API activity, and respond within agreed time | Monitoring is absent, untested, or unable to contain a campaign before material exposure |
| Third-party accountability | Contracts, scoped tokens, incident duties, and deletion/return controls are verified for relevant partners | Sundara cannot establish what a partner receives, where it goes, or how a breach is escalated |

## Identified Findings

1. **F1 — Cross-border personal-data governance is not yet a demonstrated launch control (Critical for decision).** GDPR and PDPA obligations interact across EU users, Singapore operations, and partner flows; an undocumented transfer, purpose, retention, or incident-responsibility path could force delay even if the application is technically secure.
2. **F2 — A scalable loyalty-account or cross-market authorization failure could repeat the competitor breach pattern (Critical for decision).** With 12 million active accounts, an IDOR, takeover path, or weak recovery mechanism has board-level reputational and regulatory impact.
3. **F3 — Third-party and marketing boundaries may create accountability without direct operational control (High).** Sundara must minimize data, restrict tokens, and contract for security, transfer, incident, and deletion obligations even where partner infrastructure is not in scope.
4. **F4 — Payment and reservation state transitions are high-value integrity targets (High).** Callback, replay, refund, cancellation, or market-binding weaknesses could produce direct fraud or customer harm.
5. **F5 — Location and AI recommendation data could expand the breach beyond ordinary loyalty information (High).** Excessive collection, model leakage, or partner reuse could expose sensitive behavioral profiles and undermine trust in the EU launch.
