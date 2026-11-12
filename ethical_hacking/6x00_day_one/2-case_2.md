# Case 2: The Scope Creep

## 1. What happened

RedLine Security was hired to test only the web application at `shop.clientcorp.com` and its API at `api.clientcorp.com`. A consultant discovered that the API could reach an internal billing service outside the written scope, then used a default administrator password to enter it and view billing screens containing records for more than 10,000 customers. The billing environment belonged to FinServe, a separate payment processor, and FinServe had not authorized RedLine's activity. RedLine's “bonus discovery” therefore triggered allegations of unauthorized access and PCI-DSS violations, harmed the client relationship, and led to the consultant's suspension and an insurance claim.

## 2. What rule(s), law(s), or professional standard(s) were violated

- The consultant violated the explicit scope limitation and the professional duty to stop and obtain written approval before testing an out-of-scope system.
- Accessing infrastructure owned by FinServe without FinServe's authorization may violate applicable unauthorized-access and computer-misuse laws, plus third-party contractual rights.
- Viewing names, addresses, and partial card numbers without an approved need or data-handling plan breached confidentiality and least-privilege principles and may have created privacy obligations.
- The activity was inconsistent with NIST SP 800-115, PTES, and common rules-of-engagement practice, all of which require scope control, change approval, and safe handling of evidence.
- Because payment-card data was exposed, the activity also risked violating the client's and FinServe's PCI DSS assessment and access-control requirements. PCI DSS is a contractual industry standard rather than a criminal statute, and its exact applicability depends on the parties' roles and agreements.

## 3. What the correct professional behavior would have been

The consultant should have documented the network path and the apparent firewall weakness without connecting to the billing service. The team should have notified the authorized client contact, identified FinServe as a third-party owner, and requested a formal scope change with written authorization from both ClientCorp and FinServe before any access. If approval was not obtained, the report should have described the reachable service and risk as an unvalidated observation, without attempting the default credentials or viewing billing records. Any accidentally exposed data should have been minimized, protected, reported promptly, and securely destroyed under the engagement's evidence policy.

## 4. What specific clause(s) in a pre-engagement document would have prevented this outcome

- **Explicit in-scope/out-of-scope list:** “Only `shop.clientcorp.com` and `api.clientcorp.com` are authorized targets. Internal services, third-party systems, payment environments, and discovered adjacent hosts are out of scope unless added in writing.”
- **Third-party authorization:** require a schedule naming every infrastructure owner and attaching written authorization from each owner, including FinServe, before testing that owner's systems.
- **Scope-change process:** “A consultant must not access, authenticate to, enumerate beyond, or exploit an out-of-scope asset. A scope change requires written approval from the client sponsor and the asset owner.”
- **Sensitive-data and PCI restrictions:** prohibit access to cardholder data and production customer records; require test accounts, masked data, synthetic records, and immediate stop/escalation if sensitive data becomes reachable.
- **Evidence and reporting clause:** define what may be captured, how it is encrypted and retained, and how an unvalidated out-of-scope observation must be reported without further exploitation.
- **Rules of engagement and stop conditions:** specify that discovering a route to another system is not permission to follow it, and require an immediate pause when ownership or authorization is uncertain.
