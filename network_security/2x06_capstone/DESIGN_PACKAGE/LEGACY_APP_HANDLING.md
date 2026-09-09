## 1. Objective

The Accounting team currently relies on a legacy application that uses standard FTP to upload invoices.

This protocol cannot be replaced immediately because the existing business software does not support a modern alternative.

The objective is therefore to reduce the security risk without breaking the existing workflow.

---

## 2. Current Risk

Standard FTP transmits:

- Usernames
- Passwords
- File contents

without encryption.

If FTP is exposed directly to the Internet, an attacker positioned on the network path may be able to intercept credentials or sensitive invoice data.

Direct public FTP access also increases exposure to:

- Brute-force attacks
- Credential attacks
- Service exploitation
- Automated Internet scanning

---

## 3. Tunneling Approach

The FTP application will remain unchanged.

Instead of exposing FTP directly to the Internet, Finance users must first establish an encrypted WireGuard VPN tunnel.

Target flow:

```text
Finance User
     |
     | WireGuard encrypted tunnel
     v
  Internet
     |
     v
LogiCorp Gateway
     |
     | FTP
     v
Legacy FTP Service
```

The FTP application continues to use standard FTP, but the traffic crossing the Internet is protected inside the encrypted VPN tunnel.

---

## 4. Access Restrictions

Direct FTP access from the Internet must be blocked.

Allowed flow:

```text
Finance VPN → FTP Server → ALLOW
```

Blocked flow:

```text
Internet → FTP Server → DENY
```

Only authorized Finance VPN addresses should be allowed to access the FTP service.

---

## 5. FTP Ports

The FTP control connection uses:

```text
TCP 21
```

If passive FTP is required, the configured passive port range must also be allowed from Finance VPN clients.

Example:

```text
Finance VPN → TCP 21 → ALLOW
Finance VPN → FTP Passive Range → ALLOW
Internet → TCP 21 → DENY
Internet → FTP Passive Range → DENY
```

The passive port range must be taken from the actual FTP server configuration and must not be assumed.

---

## 6. Compensating Security Controls

Because FTP itself cannot currently be replaced, the following compensating controls will be applied:

- FTP accessible only through the VPN
- Direct Internet FTP access blocked
- WireGuard encryption used across the untrusted Internet path
- Access restricted to authorized Finance users
- Firewall rules based on least privilege
- FTP passive ports restricted to the minimum required range
- Authentication attempts logged
- Suspicious FTP activity monitored
- Unnecessary FTP accounts disabled
- FTP service exposure limited to required interfaces where possible

---

# 7. Risk Acceptance

## 7.1 Accepted Risk

The organization accepts the temporary use of the FTP protocol because the Accounting software currently depends on it.

FTP remains an insecure legacy protocol because it does not provide native encryption for credentials or transferred files.

This risk cannot be completely eliminated without replacing or upgrading the legacy application.

---

## 7.2 Business Justification

Removing or replacing FTP immediately would interrupt the Accounting team's ability to upload invoices.

This would create an unacceptable operational impact.

For this reason, the legacy FTP service must remain available until the Accounting application can be modernized.

---

## 7.3 Residual Risk

Even with the VPN in place, some residual risk remains.

For example:

- FTP traffic may remain unencrypted after leaving the VPN tunnel inside the trusted infrastructure
- FTP server vulnerabilities may still exist
- Compromised Finance VPN credentials could provide access to the FTP service
- Misconfigured firewall or VPN rules could expose the service

The VPN reduces the exposure but does not make FTP itself a secure protocol.

---

## 7.4 Risk Reduction

The risk is considered reduced because:

```text
Before:

Internet → FTP
```

becomes:

```text
Finance User
     |
Encrypted VPN
     |
     v
FTP Service
```

The service is no longer directly accessible from the public Internet.

---

## 7.5 Risk Acceptance Statement

The continued use of FTP is accepted as a temporary business risk due to the dependency of the legacy Accounting application.

The risk is mitigated through an encrypted VPN tunnel, firewall restrictions, least-privilege access, logging, and monitoring.

Migration away from FTP should be planned as a future remediation project.

This statement is not valid until the following record is completed and approved:

| Field | Required value |
|---|---|
| Risk ID | `EN-01 / EN-02` |
| Risk owner | Accounting business owner |
| Technical owner | FTP service owner |
| Approver | Authorized management representative |
| Scope | Named FTP server, Finance peers and invoice workflow |
| Start date | Date of approval |
| Expiry/review date | No later than 12 months after approval |
| Migration target | Approved replacement project and target date |
| Evidence | VPN/firewall tests, monitoring test and peer inventory |

Acceptance must be reviewed after a security incident, material architecture change, new exploitable FTP vulnerability or failure of a compensating control. An expired or unsigned acceptance does not authorize continued exposure.

---

# 8. Future Recommendation

The long-term objective should be to eliminate standard FTP.

Once the legacy Accounting software can be upgraded or replaced, LogiCorp should migrate to a secure file transfer method such as:

- SFTP
- SCP
- HTTPS-based file transfer
- Another authenticated and encrypted application protocol

At that point, the temporary FTP risk acceptance can be removed.

---

# 9. Summary

The legacy FTP application will remain operational to avoid disrupting the Accounting team.

The security design does not attempt to modify the legacy software.

Instead, the exposure is reduced by requiring:

```text
Finance User
      ↓
Encrypted WireGuard VPN
      ↓
Restricted Firewall Access
      ↓
Legacy FTP Service
```

Direct Internet access to FTP is denied, and only authorized Finance VPN users are permitted to reach the service.
