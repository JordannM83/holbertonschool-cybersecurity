# 4. Know the Territory

## 1. Infrastructure Penetration Tester

### Role and positioning

An Infrastructure Penetration Tester sits in Vanguard's offensive security delivery team and leads assessments of networks, hosts, identity services, and exposed infrastructure. They work with engagement managers to define authorization and rules of engagement, with client infrastructure and security teams during testing, and with remediation owners during readouts. The role turns an attacker's view of an environment into evidence-based findings and practical risk reduction.

### Scope of intervention

This role tests internal and external networks, Active Directory and other identity services, firewalls, VPNs, remote-access services, servers, network devices, exposed management interfaces, and sometimes wireless infrastructure. Typical activity includes reconnaissance, vulnerability validation, credential and privilege testing, lateral-movement simulation, and controlled post-exploitation. It does not primarily assess application source code and business logic, cloud-native configuration, mobile binaries, human susceptibility, physical security, or industrial control systems; those require the specialist roles described below and must not be assumed to be included in a network scope.

### Key skills

- Strong TCP/IP, DNS, HTTP, TLS, routing, Windows and Linux administration knowledge.
- Practical Active Directory attack and defense knowledge: Kerberos, NTLM, LDAP, delegation, trusts, Group Policy, and privilege paths.
- Ability to use and adapt tools such as Nmap, Burp Suite for infrastructure-adjacent HTTP work, Impacket, BloodHound, Metasploit, Responder, and common credential-testing tooling.
- Scripting and automation in Python, PowerShell, or Bash, including the ability to validate a tool's output rather than blindly trust it.
- Safe exploitation, evidence collection, impact control, and disciplined handling of credentials and production data.
- Clear technical writing: explain an attack path to both a system administrator and an executive without exaggerating severity.
- Calm coordination during disruptive findings, good time management across large address ranges, and willingness to stop when authorization or safety is uncertain.

### Relevant certifications

- **OffSec OSCP:** validates hands-on network exploitation, privilege escalation, pivoting, and reporting under time constraints; it maps closely to the practical core of the role.
- **CREST Practitioner Security Analyst (CPSA) or CRT:** demonstrates structured penetration-testing knowledge and professional assessment practice, particularly useful where clients require an industry assessment standard.
- **GIAC Penetration Tester (GPEN):** reinforces formal methodology, network and host testing, and defensible evidence collection; it is useful for consultants who must explain why a test result is reliable.

### Distinction from adjacent roles

Unlike the Web Application Security Consultant, this tester focuses on hosts, network paths, identity infrastructure, and operating-system privilege rather than application logic and authorization flaws. Unlike the Cloud Security Assessor, the primary target is conventional enterprise infrastructure, even when it connects to cloud services. Unlike a Red Team Operator, the infrastructure tester normally performs a bounded technical assessment to identify and validate weaknesses rather than running a broad stealth campaign against people, facilities, and detection capabilities. Mobile, social-engineering, and IoT/OT testing are separate specialties with different platforms, safety constraints, and evidence requirements.

### Typical engagement scenario

During scoping, the tester confirms the client's owned CIDR ranges, external addresses, internal segments, test windows, credentials, prohibited systems, and emergency contacts. They perform external reconnaissance and controlled vulnerability validation, then conduct an authenticated internal assessment focused on Active Directory privilege paths and segmentation. A discovered route from a user workstation to domain administrator is demonstrated with a controlled proof, without dumping unnecessary production data or making persistence changes. The final deliverable contains an executive summary, attack-path narrative, reproducible technical evidence, prioritized remediation, and a retest plan, followed by a technical readout with the infrastructure team.

## 2. Web Application Security Consultant

### Role and positioning

The Web Application Security Consultant is the application-focused specialist within Vanguard's offensive security practice. They partner with engagement managers, product owners, developers, DevOps engineers, architects, and client security teams to test how an application behaves under malicious input and unauthorized workflows. They may lead an application assessment or contribute the application workstream to a larger infrastructure or cloud engagement.

### Scope of intervention

This role assesses browser applications, APIs, authentication and session management, authorization, business logic, input handling, file processing, integrations, and application-level configuration. It uses manual testing and automation to investigate issues such as injection, broken access control, SSRF, insecure deserialization, race conditions, and sensitive-data exposure. It is not primarily responsible for network segmentation, operating-system hardening, cloud tenant architecture, mobile reverse engineering, phishing, physical intrusion, or the safety-critical testing of IoT/OT environments. Source-code review may be included when contracted, but it should not be assumed from a black-box web test.

### Key skills

- Deep understanding of HTTP, cookies, TLS, browsers, REST, GraphQL, WebSockets, JSON, OAuth/OIDC, SAML, and common API patterns.
- Ability to reason about authorization and business workflows, including multi-tenant isolation, privilege transitions, race conditions, and abuse cases.
- Expert practical use of Burp Suite or an equivalent proxy, plus scripting in Python or JavaScript to build targeted requests and repeatable checks.
- Familiarity with OWASP Top 10, OWASP API Security Top 10, secure SDLC practices, threat modeling, and modern CI/CD architectures.
- Ability to read code and traces in common stacks such as Java, .NET, Python, JavaScript/TypeScript, and SQL, even when source review is not part of the engagement.
- Careful handling of production data, test accounts, rate limits, and destructive actions.
- Strong interviewing and writing skills: ask developers precise questions, reproduce defects clearly, and explain business impact in terms of an abuse case.

### Relevant certifications

- **OffSec OSWE:** focuses on advanced web exploitation and source-assisted analysis, demonstrating the ability to move beyond scanner findings into code and logic-level vulnerabilities.
- **Burp Suite Certified Practitioner (BSCP):** tests practical web-security testing with the tool used daily for request manipulation, authentication testing, and vulnerability validation.
- **GIAC Web Application Penetration Tester (GWAPT):** covers a broad, structured web assessment methodology and helps demonstrate competence across common application vulnerability classes.

### Distinction from adjacent roles

Unlike the Infrastructure Penetration Tester, this consultant follows application workflows and trust boundaries rather than primarily attacking operating systems, networks, or Active Directory. Unlike the Mobile Application Penetration Tester, the target is a web or API service and its browser-facing behavior, not an installed mobile client and its local storage, IPC, or binary. Unlike the Social Engineering Specialist, this role tests software controls rather than employee behavior. It can uncover cloud or infrastructure weaknesses that are visible through an application, but ownership of the underlying cloud architecture belongs to the Cloud Security Assessor unless explicitly added to scope.

### Typical engagement scenario

The consultant begins by confirming application URLs, API hosts, roles, test accounts, tenant boundaries, data sensitivity, rate limits, and permitted business actions. They map the application's attack surface, test authentication and authorization across roles and tenants, and manually validate high-risk workflows such as refunds, account recovery, and file upload. An IDOR is demonstrated with test accounts and minimal data, while a suspected SSRF is validated against an approved canary rather than an uncontrolled internal target. The deliverable includes reproducible requests, affected endpoints and roles, business impact, remediation guidance for developers, and a retest of the fixes.

## 3. Cloud Security Assessor

### Role and positioning

The Cloud Security Assessor sits between Vanguard's offensive testing and cloud architecture practices. They evaluate whether a client's cloud accounts, identities, services, network controls, and delivery pipelines resist realistic compromise paths. They work with cloud platform engineers, DevSecOps teams, architects, incident responders, and governance stakeholders, and may coordinate with infrastructure or application testers when an attack crosses boundaries.

### Scope of intervention

This role assesses cloud control planes and workloads in platforms such as AWS, Azure, and Google Cloud: IAM, organizations and subscriptions, storage, serverless services, containers, Kubernetes, secrets, logging, network exposure, CI/CD, and cross-account or cross-project trust. Depending on authorization, it may include configuration review, attack-path analysis, assumed-role testing, cloud penetration testing, and controlled exploitation of exposed workloads. It is not automatically a conventional network test, a web application source-code review, a mobile assessment, a social-engineering campaign, a physical intrusion, or an IoT/OT safety test. Cloud-provider acceptable-use rules and shared-responsibility boundaries must be checked before any exploitation.

### Key skills

- Practical command of AWS, Azure, and/or Google Cloud IAM, networking, logging, storage, compute, serverless, containers, and organizational structures.
- Understanding of cloud identity attack paths: over-permissive roles, trust policies, metadata services, federation, workload identities, secrets, and privilege escalation.
- Familiarity with Kubernetes, Docker, Terraform or another infrastructure-as-code tool, CI/CD systems, and software supply-chain risks.
- Ability to use provider-native tooling and security services alongside tools such as ScoutSuite, Prowler, Pacu, cloud CLIs, and policy-as-code checks, while validating findings manually.
- Knowledge of shared responsibility, data residency, provider rules, rate limits, and safe testing methods that avoid tenant-wide or production outages.
- Strong architectural reasoning: connect a misconfiguration to a realistic attack path and a practical control, not merely a checklist item.
- Collaborative communication with platform teams, including the ability to explain identity and architecture risk to non-specialists.

### Relevant certifications

- **CCSK (Certificate of Cloud Security Knowledge):** establishes a vendor-neutral foundation in cloud governance, architecture, shared responsibility, and control selection.
- **AWS Certified Security – Specialty** (or an equivalent Azure/GCP security specialty): demonstrates practical knowledge of cloud-native identity, monitoring, data protection, and incident controls on a major platform.
- **GIAC Cloud Penetration Tester (GCPN):** is directly relevant to hands-on cloud attack paths, exploitation techniques, and validation of cloud-specific weaknesses rather than only configuration auditing.

### Distinction from adjacent roles

Unlike the Infrastructure Penetration Tester, the Cloud Security Assessor focuses on provider control planes, ephemeral workloads, federated identities, and cloud service relationships rather than only traditional hosts and networks. Unlike the Web Application Security Consultant, the target is the application's surrounding cloud architecture and deployment environment, not primarily its endpoints and business logic. Unlike a Red Team Operator, the assessor normally prioritizes cloud attack paths and control validation over a broad covert campaign. Mobile, social-engineering, and IoT/OT roles address different platforms and threat models; a cloud-hosted application may involve several of these roles, but cloud ownership does not erase their boundaries.

### Typical engagement scenario

At kickoff, the assessor inventories cloud accounts, subscriptions, projects, regions, tenant boundaries, provider approvals, test identities, sensitive workloads, and explicit no-touch resources. They combine configuration review with controlled attack-path testing, showing how a compromised CI/CD role could reach a production storage bucket or escalate through a cross-account trust. The team validates impact using canary objects and approved test data, while coordinating with the client's SOC so alerts and rollback procedures are understood. The final report maps each path to affected principals and resources, explains the control failure, recommends least-privilege and monitoring changes, and includes a retest of the corrected policies.

## Why these three roles

I chose the Infrastructure Penetration Tester, Web Application Security Consultant, and Cloud Security Assessor because they cover the three technical layers present in most modern client environments: enterprise infrastructure and identity, exposed applications and APIs, and cloud control planes and workloads. Together they can test the paths an attacker commonly uses from an internet-facing application or identity compromise into internal or cloud resources. They also create useful collaboration without collapsing distinct responsibilities: each role has a clear target, methodology, and remediation audience. Red teaming, social engineering, and physical testing remain valuable, but they are higher-coordination capabilities that should be added when a client's maturity and objectives justify them. Mobile and IoT/OT specialists are similarly important for clients with those product or operational profiles, but they are more market-specific than this initial trio. This hiring plan suggests Vanguard is building a broad, repeatable core delivery capability first, with room to extend into adversary simulation and specialized domains as demand grows.
