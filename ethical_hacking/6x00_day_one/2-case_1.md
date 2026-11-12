# Case 1: The Handshake Deal

## 1. What happened

NorthBay Consulting started a network penetration test based only on a phone call between its account manager and the client's CTO. The team found a SQL injection vulnerability, exploited it, and extracted 500 shipping records containing personal and shipment information. The client's General Counsel and CEO had not been told about the engagement, so the SIEM alert was treated as a real breach and reported to the data protection authority. The CTO had no documented authority to grant third-party access, and NorthBay consequently faced a cease-and-desist, an insurance investigation, regulatory scrutiny, and eight months of legal proceedings.

## 2. What rule(s), law(s), or professional standard(s) were violated

- NorthBay violated the core professional requirement to obtain clear, written, and verifiable authorization from an authorized representative before testing. A verbal assurance from a person whose authority was not verified is not sufficient for intrusive testing.
- Accessing systems and extracting records without valid authorization may violate applicable unauthorized-access and computer-misuse laws, such as the Computer Fraud and Abuse Act (CFAA) where applicable, as well as contractual and civil law.
- The handling of customer addresses and package contents raised privacy, confidentiality, and data-minimization obligations. If the organization was subject to a data-protection regime such as the GDPR, the incident also created potential personal-data breach notification and processor obligations.
- The conduct was inconsistent with recognized penetration-testing practice, including NIST SP 800-115 and PTES principles requiring defined scope, rules of engagement, authorization, and agreed handling of discovered data.

## 3. What the correct professional behavior would have been

NorthBay should have paused until it had a signed statement of work and authorization letter from a person with confirmed legal authority to authorize testing. It should have verified that the CEO, General Counsel, security leadership, incident-response provider, insurer, and relevant operations staff knew the test window and escalation contacts. After finding the SQL injection, the team should have demonstrated impact with the least data possible, using a synthetic record or a single minimally sensitive record rather than extracting 500 records. It should also have followed the agreed stop conditions and immediately reported the discovery through the designated client contact.

## 4. What specific clause(s) in a pre-engagement document would have prevented this outcome

- **Authority and written authorization:** “Testing may begin only after the client signs this agreement and an authorization letter. The client represents that the signatory has authority to authorize access to every in-scope system and data set.”
- **Named stakeholders and notification:** identify the executive sponsor, General Counsel/privacy contact, SOC/incident-response provider, insurer contact, and 24-hour emergency contacts; require advance notice to them before testing starts.
- **Scope and test window:** list exact systems, domains, source IPs, dates, times, methods, and prohibited actions.
- **Data-handling limits:** prohibit copying production data; require synthetic or minimum necessary samples, encryption, retention limits, secure deletion, and immediate notification of any sensitive-data access.
- **Stop and escalation procedure:** require testing to stop on a SIEM alert, suspected compromise, service impact, or unexpected sensitive-data exposure until the named client authority gives written permission to resume.
- **Third-party and legal authorization:** require confirmation that the client owns or is authorized to test all infrastructure and that relevant contractual, regulatory, and insurance approvals are in place.
