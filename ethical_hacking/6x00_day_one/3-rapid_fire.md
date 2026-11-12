# 3. The Rapid Fire

## Cluster A: Scope Boundaries

### Vignette 1

**CAN you?**

Not automatically. “The web application and its direct dependencies” is ambiguous: the API may be a direct dependency, but it may also be a separately owned or separately operated system. A penetration tester should confirm that interpretation with the authorized client contact and verify ownership before sending requests or exploiting the authentication bypass. Unless the signed scope clearly includes that API, testing it without written clarification could be a contractual scope violation and, if it is owned by another party, unauthorized access.

**SHOULD you?**

You should not exploit it immediately. You should record how the web application depends on the API, preserve only the minimum evidence needed, and notify the client that a potentially critical out-of-scope system is reachable. With written scope confirmation, you could perform controlled validation using the least intrusive method and agreed test accounts. This approach preserves the value of the discovery while avoiding an assumption that a broad phrase authorizes access to another system.

### Vignette 2

**CAN you?**

No, not on the facts given. The signed scope is limited to `10.0.1.0/24`, and `10.0.2.15` is outside that range. A comment during kickoff is useful context but does not replace written authorization, especially where the host is a development environment that may have a different owner, data set, or risk profile. Accessing the default credentials could therefore breach the contract and potentially constitute unauthorized access.

**SHOULD you?**

You should not access it. The correct action is to document the responding address and the fact that the client mentioned a dev environment, then ask the authorized project contact to confirm ownership and approve a scope change. If approved, the test should define the permitted hosts, credentials, timing, and data-handling rules. The default password makes the host important, but urgency does not create permission.

### Vignette 3

**CAN you?**

Possibly, but only to the extent that the written authorization covers the relevant data and testing method. Authorization to test the application does not necessarily authorize unrestricted access to real customer records, payment data, or data held for another controller or processor. If the contract and rules of engagement expressly permit controlled production-data validation, a minimal proof may be allowed; otherwise, accessing actual records beyond what is necessary could violate privacy law, data-processing terms, PCI-related obligations, or the engagement contract.

**SHOULD you?**

You should avoid accessing real customer data whenever a safer proof is available. First use a test account, synthetic records, a non-sensitive field, or a single masked record, and stop once the IDOR is proven. If real PII is unavoidably exposed, view and retain the minimum necessary, do not download or alter it, notify the designated client privacy/security contact immediately, and follow the agreed evidence-destruction process. Demonstrating impact does not justify collecting a customer dataset.

## Cluster B: Incidental Discoveries

### Vignette 4

**CAN you?**

Generally, yes, you can report it to the client because the evidence was encountered on an in-scope workstation during an authorized engagement and the client is the party responsible for its environment. However, you should not assume that the penetration-test contract authorizes a separate fraud investigation or disclosure to third parties. Preserve the evidence carefully, limit access to the agreed client contacts, and follow any confidentiality, legal-hold, and escalation clauses.

**SHOULD you?**

Yes, you should report the discovery, but neutrally and through the designated channel. State what was observed, where and when it was found, and what evidence exists; do not conclude that a named employee committed fraud or conduct additional surveillance. The client can involve legal counsel, compliance, HR, or law enforcement. Suppressing a serious discovery would be unprofessional, while independently investigating or publicly disclosing it would exceed the tester's role.

### Vignette 5

**CAN you?**

Generally, yes, you can include the observation in a confidential report to the authorized hospital client, because it was encountered in an in-scope EHR during authorized testing. The report should account for medical privacy, minimum-necessary disclosure, and the possibility that the EHR or hospital is governed by sector-specific requirements such as HIPAA. You should not disclose it to the physician, the public, or an outside party unless the contract, law, or an emergency escalation process requires that step.

**SHOULD you?**

Yes, you should escalate it promptly, but as an observed potential abuse of access rather than a definitive criminal or clinical finding. Include only the minimum identifiers and evidence needed for the hospital's privacy, compliance, legal, and security teams to investigate. Do not alter records, confront the physician, or continue browsing unrelated patient records. The engagement's security purpose does not excuse ignoring a serious patient-safety and privacy risk, but it also does not make the tester the investigator.

## Cluster C: Client Communication

### Vignette 6

**CAN you?**

Yes. A rule saying findings will be reported in the final report should not be read as preventing emergency notification of an active compromise. The Rules of Engagement should be interpreted together with any emergency, safety, incident-response, or stop-testing provisions; if they truly contain no emergency path, the tester should use the firm's authorized escalation process and document why immediate notice was necessary. Notification is within the purpose of protecting the client and does not require waiting for the scheduled deliverable.

**SHOULD you?**

Absolutely. An actively exploited RCE with indicators of compromise is an urgent incident, not an ordinary finding. Notify the named emergency contact immediately, explain what was observed and what is known versus inferred, avoid destructive remediation unless authorized, and coordinate a safe pause or transition to incident response. Waiting two weeks would expose the client to continuing harm and would violate the duty of care, even if the final-report clause was drafted poorly.

### Vignette 7

**CAN you?**

Not by simply accepting the request. The Rules of Engagement expressly require communications through the project manager, so sharing preliminary findings directly with the CISO would breach the agreed communication procedure unless the CISO is also an authorized exception under the contract. You should verify the CISO's identity and authority, attempt the documented backup or escalation contact, and seek written authorization for an exception. A vacation does not automatically suspend the communication clause.

**SHOULD you?**

You should not bypass the process casually, because preliminary findings may be unvalidated, incomplete, or misleading when presented to the board. You should promptly tell the CISO that the request must be routed through the designated process, contact the firm's engagement lead or backup, and offer a controlled briefing after approval. If the finding represents an urgent material risk, use the emergency escalation path and provide only verified, necessary information rather than withholding a serious warning until the project manager returns.

## Cluster D: Engagement Qualification

### Vignette 8

**CAN you?**

Yes, you can propose an engagement, but you cannot responsibly treat “the full works” or “surprise us” as a legally sufficient scope. Before any testing, the firm would need a signed agreement, an authorized signatory, defined targets and methods, rules of engagement, emergency contacts, data-handling terms, and any third-party or physical-testing approvals. The lack of a security team does not remove the CEO's ability to authorize testing, but it increases the need to verify authority, prepare the client, and define who will respond to findings.

**SHOULD you?**

You should not jump straight to an unrestricted red-team operation. A 50-person startup with no prior assessment and a three-person IT department likely needs a staged engagement: asset and threat discovery, vulnerability assessment or scoped penetration test, remediation support, and then a targeted adversary simulation based on identified risks. Explain what a red team can and cannot establish, ask about critical assets and business downtime tolerance, and create a safe communication and incident-response plan. A surprise exercise may be appropriate later, but proposing an undefined full-scope attack now would be poor qualification and could create avoidable operational, legal, and safety risks.
