# LogiCorp Gap Analysis Report

## 1. Executive Summary

LogiCorp's current network presents several critical security weaknesses, including a flat network architecture, unrestricted Internet-facing SSH access, cleartext FTP traffic, and the absence of an active firewall.

The immediate priority is to reduce the external attack surface, isolate critical systems such as the central database, and secure remote access while preserving the legacy FTP workflow required by the Accounting team.

---

## 2. Scope and Methodology

This assessment is based exclusively on the documentation provided in the LogiCorp Briefing Pack.

No technical validation, command execution, network scanning, configuration review, or live-system access has been performed at this stage.

The analysis compares:

- **Current State:** The environment described in the documentation.
- **Target State:** The expected secure posture based on the client's requirements and common security best practices.
- **Gap:** The difference between the current and target states.
- **Risk:** The potential business or technical impact.
- **Severity:** Critical, High, Medium, or Low.

Because the existing documentation may be inaccurate or incomplete, all findings must later be validated against the live environment.

---

# 3. Current State Assessment

Based on the Briefing Pack, LogiCorp currently operates a single Linux Gateway that manages multiple network functions.

The infrastructure has reportedly grown organically for approximately ten years without a dedicated security administrator.

## 3.1 Network Architecture

The current network is documented as a flat network using the `192.168.1.x` subnet.

The following systems appear to share the same network segment:

- Office workstations
- Finance workstations
- Guest WiFi
- Critical central database
- Linux Gateway

There is currently no documented separation between trusted users, untrusted guest devices, critical systems, or public-facing services.

The target architecture is expected to support:

- WAN
- Internal LAN
- DMZ

---

## 3.2 Remote Access

SSH is currently exposed directly to the Internet.

The documentation also states that:

- SSH is accessible from any Internet source.
- Root login is enabled.
- Remote access is required for server maintenance.

The client wants to preserve remote administration capabilities but does not want SSH exposed publicly.

---

## 3.3 Legacy FTP Service

The Accounting team works remotely and uploads invoices using FTP.

The current FTP service operates in cleartext.

The client has explicitly stated that the FTP-based workflow cannot currently be replaced because the accounting software is too old.

Therefore, the security solution must protect this legacy service without breaking the business workflow.

---

## 3.4 Firewalling

The target security policy is a **Default Deny** model.

However, the documentation states that no firewall is currently active.

This means there is no documented network-level control restricting traffic based on source, destination, protocol, or service.

---

## 3.5 Critical Database

The shipping application depends on a central database hosted at LogiCorp headquarters.

The CEO specifically requires this database to be isolated from the outside world.

According to the current diagram, the database is located on the same network segment as:

- Office workstations
- Finance systems
- Guest WiFi

This significantly increases the database's exposure to internal threats and lateral movement.

---

## 3.6 Infrastructure Resilience

The Linux Gateway represents a single point of failure.

However, redundancy is explicitly identified as outside the current project scope.

---

# 4. Critical Gaps Identified

## 4.1 Network Architecture Gaps

### NA-01 — Flat Network Architecture

**Current State:**  
Office systems, Finance systems, Guest WiFi, and the critical database are documented as being connected to the same `192.168.1.x` network.

**Target State:**  
Systems with different trust levels should be separated into distinct security zones such as LAN, DMZ, Guest, and critical server networks.

**Gap:**  
There is no documented network segmentation between trusted, untrusted, and critical systems.

**Risk:**  
If a workstation or guest device becomes compromised, an attacker may be able to directly communicate with and attack critical infrastructure, including the central database.

**Severity:** Critical

---

### NA-02 — No Dedicated DMZ

**Current State:**  
The current architecture does not document any DMZ.

**Target State:**  
Public-facing or externally reachable services should be isolated from the internal network inside a dedicated DMZ.

**Gap:**  
Externally accessible services may currently share network access with internal systems.

**Risk:**  
A compromised Internet-facing service could provide an attacker with a direct path toward internal systems.

**Severity:** High

---

### NA-03 — Critical Database Not Isolated

**Current State:**  
The database appears to share the same network segment as user and guest devices.

**Target State:**  
The database should be placed in a dedicated protected network zone and should only accept connections from explicitly authorized systems.

**Gap:**  
There is no documented network-level isolation protecting the database.

**Risk:**  
Compromised internal devices may be able to scan, attack, or directly communicate with the database.

**Severity:** Critical

---

# 4.2 Access Control Gaps

### AC-01 — SSH Exposed to the Entire Internet

**Current State:**  
SSH is accessible from the public Internet without documented source restrictions.

**Target State:**  
Administrative access should only be available to authorized personnel through a controlled remote-access mechanism such as a VPN.

**Gap:**  
The SSH service is directly exposed to untrusted Internet hosts.

**Risk:**  
The server is exposed to password attacks, credential stuffing, automated scanning, and potential SSH vulnerabilities.

**Severity:** Critical

---

### AC-02 — Remote Root Login Enabled

**Current State:**  
Root login through SSH is enabled.

**Target State:**  
Direct remote root login should be disabled. Administrators should authenticate using individual accounts and elevate privileges only when required.

**Gap:**  
The most privileged system account can be accessed directly through a remotely exposed service.

**Risk:**  
Compromise of the root credentials could immediately result in complete control of the gateway.

**Severity:** Critical

---

### AC-03 — No Documented Least-Privilege Network Policy

**Current State:**  
No firewall is active and systems appear to share a common network.

**Target State:**  
Systems should only be able to communicate with services that are strictly required for business operations.

**Gap:**  
There are no documented access restrictions between network zones or systems.

**Risk:**  
Attackers may gain unnecessary network access following the compromise of a single device.

**Severity:** High

---

# 4.3 Encryption Gaps

### EN-01 — FTP Transmits Data in Cleartext

**Current State:**  
The Accounting team uploads invoices using standard FTP.

**Target State:**  
Sensitive data and authentication credentials should be protected by encryption while in transit.

**Gap:**  
FTP does not provide confidentiality for credentials or transferred data.

**Risk:**  
An attacker capable of observing network traffic may intercept FTP credentials or sensitive invoices.

**Severity:** High

---

### EN-02 — Legacy FTP Cannot Be Replaced Immediately

**Current State:**  
The Accounting software requires FTP and cannot currently be modified.

**Target State:**  
Legacy traffic should be protected even when the application itself cannot support modern encryption.

**Gap:**  
The insecure protocol must remain operational due to a business constraint.

**Risk:**  
Removing FTP could interrupt business operations, while leaving it directly exposed would maintain a significant security risk.

**Severity:** High

**Preliminary Approach:**  
Restrict FTP access so that it is only reachable through a trusted encrypted network path, such as a VPN, rather than directly exposing FTP to the Internet.

---

# 4.4 Monitoring Gaps

### MO-01 — No Documented Security Monitoring

**Current State:**  
The Briefing Pack does not describe any centralized logging, intrusion detection, alerting, or active security monitoring.

**Target State:**  
Security-relevant activity should be logged and reviewed.

**Gap:**  
The existing monitoring posture cannot be confirmed from documentation.

**Risk:**  
Suspicious activity or future compromises may remain undetected for an extended period.

**Severity:** High

---

### MO-02 — No Documented Authentication Monitoring

**Current State:**  
SSH is exposed to the Internet, but the documentation does not describe monitoring of authentication attempts.

**Target State:**  
Repeated authentication failures, privileged logins, and suspicious remote-access attempts should be monitored.

**Gap:**  
There is no documented capability for detecting brute-force or suspicious authentication activity.

**Risk:**  
Attacks against remote administration services may go unnoticed.

**Severity:** High

---

# 5. Risk Matrix

| ID | Category | Gap | Likelihood | Impact | Severity |
|---|---|---|---|---|---|
| NA-01 | Network Architecture | Flat network architecture | High | Critical | Critical |
| NA-02 | Network Architecture | No dedicated DMZ | Medium | High | High |
| NA-03 | Network Architecture | Database not isolated | High | Critical | Critical |
| AC-01 | Access Control | SSH exposed to Internet | High | Critical | Critical |
| AC-02 | Access Control | Remote root login enabled | High | Critical | Critical |
| AC-03 | Access Control | No least-privilege network policy | High | High | High |
| EN-01 | Encryption | Cleartext FTP | High | High | High |
| EN-02 | Encryption | Legacy FTP dependency | High | High | High |
| MO-01 | Monitoring | No documented security monitoring | Medium | High | High |
| MO-02 | Monitoring | No documented authentication monitoring | Medium | High | High |

---

# 6. Preliminary Recommendations

## 6.1 Implement Network Segmentation

Redesign the network around separate trust zones.

A preliminary target architecture should include:

- WAN
- Internal LAN
- Guest network
- DMZ
- Critical database/server network

Traffic between these zones should be explicitly controlled.

The database should only accept connections from systems that legitimately require access.

---

## 6.2 Implement a Default-Deny Firewall

Deploy a host-based firewall on the Linux Gateway.

The firewall should follow a **Default Deny** model:

> Deny all traffic unless it is explicitly required.

Rules should then explicitly allow required business services based on:

- Source
- Destination
- Protocol
- Port
- Connection state

---

## 6.3 Deploy Secure Remote Access

Administrative access should no longer expose SSH directly to the Internet.

A VPN should be used as the primary remote-access mechanism.

The expected flow should become:

`Administrator → VPN → Internal SSH service`

SSH should only accept connections from the VPN or other explicitly trusted administrative networks.

Direct root SSH login should also be disabled.

---

## 6.4 Protect the Legacy FTP Workflow

Because FTP cannot immediately be replaced, the service should not simply be removed.

Instead, its exposure should be reduced.

A possible architecture is:

`Accounting User → Encrypted VPN → FTP Server`

This allows the legacy application to continue using FTP while the untrusted Internet portion of the communication is protected by the VPN tunnel.

FTP should only accept connections originating from authorized VPN clients or trusted networks.

---

## 6.5 Isolate the Critical Database

The central database should be placed in a dedicated security zone.

Firewall rules should explicitly define which systems may access the database.

Access from the following networks should normally be denied unless a documented business requirement exists:

- Internet
- Guest WiFi
- General user workstations
- DMZ services

---

## 6.6 Improve Monitoring and Logging

The technical assessment should determine what logging capabilities currently exist.

At minimum, the future security posture should include monitoring for:

- Successful and failed SSH authentication
- VPN connections
- Privileged activity
- Firewall drops
- FTP authentication
- Suspicious connection attempts
- Administrative actions

Logs should be retained long enough to support incident investigation.

---

# 7. Proposed Target Architecture

A preliminary logical target could resemble:

```text
                         Internet
                            |
                         [Modem]
                            |
                     [Linux Gateway]
                            |
          +-----------------+------------------+
          |                 |                  |
        [DMZ]          [Internal LAN]       [Guest]
                             |
                       [Server Zone]
                             |
                         [Database]
```

Remote administration:

```text
Administrator
     |
 Internet
     |
   VPN
     |
Linux Gateway
     |
    SSH
```

Legacy Accounting access:

```text
Accounting User
      |
   Internet
      |
     VPN
      |
 FTP Service
```

The exact physical and logical architecture must be confirmed during the live technical assessment.

---

# 8. Documentation Uncertainties

The Project Manager explicitly warned that the existing diagram may be inaccurate.

Therefore, the following elements must not yet be considered confirmed:

- Actual interface configuration
- Actual subnet structure
- Active services
- Listening ports
- Firewall configuration
- Routing configuration
- NAT configuration
- Database location
- FTP server location
- SSH configuration
- User accounts
- Existing VPN configuration
- Actual physical topology

These elements must be discovered and validated during the technical assessment.

---

# 9. Next Steps

Before implementing changes, the technical assessment should:

1. Identify all network interfaces.
2. Determine the actual IP addressing and routing configuration.
3. Identify active and listening services.
4. Identify externally exposed services.
5. Inspect SSH configuration.
6. Inspect FTP configuration.
7. Verify whether any firewall rules already exist.
8. Determine the location of the critical database.
9. Identify dependencies between internal systems.
10. Compare the discovered environment with the documented architecture.

Only after the actual environment is understood should the target architecture and remediation plan be finalized.

---

# 10. Conclusion

The documentation indicates that LogiCorp currently operates with several high-risk security weaknesses, particularly unrestricted administrative exposure, lack of network segmentation, cleartext legacy traffic, and insufficient network access control.

The remediation strategy should prioritize containment and segmentation while respecting the company's operational constraints. In particular, the legacy FTP workflow should be preserved but isolated behind secure access controls rather than exposed directly to the Internet.

All findings in this report remain preliminary until validated against the live environment.
