# LogiCorp Security Defense

This document explains the security decisions in the capstone implementation,
including the risks that remain. The implementation values in
`HARDENING/config.sh` are the source of truth: the gateway uses `wg0`, the
`10.8.0.0/24` VPN network, UDP/51820, SSH TCP/22, Finance FTP TCP/21 plus
TCP/50000-50100, and database TCP/3306.

## Challenge 1 — Risk acceptance: legacy FTP

### Business constraint

Finance currently depends on an old accounting application that uploads
invoices through an FTP-compatible workflow. Replacing it immediately would
require application changes, user retraining, testing, and coordination with
the accounting software vendor. An immediate SFTP-only change could interrupt
invoice processing and create a larger business impact than the short-term
security improvement. The current project therefore protects the workflow
while recording the protocol replacement as technical debt.

### Mitigations implemented

FTP is not exposed as a public service. A Finance device must first authenticate
to the WireGuard VPN, receive its assigned peer address (`FINANCE_VPN_IP`),
and then pass the firewall's source, destination, interface, and port checks.
The firewall allows only the configured FTP control port and passive range to
the approved Finance flow. It denies direct WAN access and unrelated access to
the LAN, database, and other zones.

The FTP service is also hardened by `clean.sh`:

- anonymous access is disabled;
- TLS is enabled;
- local logins and data transfers require TLS;
- the passive range is explicitly limited to `FTP_PASSIVE_MIN` through
  `FTP_PASSIVE_MAX`;
- the service configuration and certificate key are protected with restrictive
  file permissions.

The VPN uses per-device WireGuard keys and per-peer addresses. Lost or retired
peers can be revoked without changing every other client. The validation
script checks the firewall rules, service configuration, and passive range
after changes.

### Residual risk

This is risk reduction, not risk elimination. FTP remains a legacy protocol,
and the accounting application still has a larger compatibility and attack
surface than an SFTP workflow. A compromised Finance endpoint or stolen VPN
key could still be used to attempt the narrowly permitted service. The business
owner must therefore formally accept this residual risk until migration is
complete. Monitoring, peer review, key revocation, and firewall logging are
required compensating controls.

### Phase 2 recommendation

Run a controlled SFTP migration with the accounting vendor. Operate SFTP in
parallel, test invoice upload/download and recovery, migrate one Finance user
first, then disable FTP after an agreed rollback period. The Phase 2 exit
criteria should include successful business testing, key ownership and
rotation procedures, MFA where supported, and removal of the FTP ports and
passive-range rules from the firewall.

## Challenge 2 — Firewall strategy and lateral movement

### Zones and trust levels

The design separates traffic by function rather than trusting everyone on the
same network:

| Zone | Trust level | Policy |
|---|---|---|
| WAN | Untrusted | Only the WireGuard endpoint is exposed |
| VPN (`wg0`) | Authenticated but not fully trusted | Access is granted per peer and role |
| LAN | Trusted user network | Not reachable by default from VPN, Guest, or DMZ |
| Guest | Untrusted internal | Internet access only where explicitly approved |
| DMZ | Restricted service zone | Hosts legacy or published services; no implicit LAN access |
| Database | Highest protection | Accepts only the documented application flow |

Authentication to the VPN is not authorization to the whole network. The
firewall still evaluates each source address, interface, destination, protocol,
and port.

### Traffic restrictions

The nftables policy uses default `DROP` for `input`, `forward`, and `output`.
Established and related return traffic is allowed, but new traffic requires a
specific rule. The implementation permits:

- WireGuard UDP/51820 to establish the tunnel;
- the IT peer address to reach gateway SSH TCP/22;
- the Finance peer address to reach only the approved FTP control and passive
  ports;
- the database peer address to reach the configured database port;
- loopback traffic and required established sessions.

There is no general “VPN users may access the LAN” rule, no WAN-to-SSH rule,
and no broad inter-zone allow rule. IPv6 must receive equivalent filtering or
remain disabled so it cannot bypass the IPv4 policy.

### How the previous attack path is blocked

Previously, a compromised workstation or guest device on a flat network could
scan and directly connect to the database and other hosts. Under the target
model, Guest-to-LAN, Guest-to-Database, DMZ-to-LAN, and unauthorized
VPN-to-Database flows have no matching allow rule and hit the default drop.
A compromised legacy service is confined to its DMZ role; reaching another
zone requires a separately approved flow. Public SSH is also removed as an
entry point, so an attacker cannot use Internet exposure to begin the same
lateral path.

### Defense in depth

Segmentation is combined with multiple independent controls: WireGuard key
authentication, peer-specific addressing, default-deny stateful filtering,
SSH public-key-only access with root login disabled, TLS for the legacy file
service, stopped unnecessary services, IP forwarding limited to the gateway
role, logging of denied traffic, and automated regression checks. If one layer
is misconfigured, the others reduce the attacker's ability to move or persist.

## Challenge 3 — Gateway resilience

### Scope and current exposure

High availability was explicitly outside this phase's scope. The gateway is
therefore still a single point of failure for VPN access, firewall enforcement,
and any routing that depends on it. If it fails, remote administration and
Finance access through the VPN stop until the gateway is repaired or a known
good configuration is restored. This is primarily an availability risk; the
default-deny posture should fail closed rather than expose the internal
network.

The current controls reduce compromise risk but do not provide continuity.
Backups, the panic rollback mechanism, documented recovery commands, and
configuration validation shorten recovery time, but they are not a substitute
for a second gateway.

### Phase 2 high-level HA plan

Evaluate an active/passive pair of hardened gateways with:

1. two independent hosts, power paths, and upstream connectivity where
   practical;
2. a virtual gateway address managed by a health-checked failover mechanism;
3. replicated nftables policy, WireGuard peer inventory, routes, and approved
   configuration versions;
4. carefully designed WireGuard key and state handling during failover;
5. monitoring for service, interface, route, and peer health;
6. regular, documented failover and recovery exercises.

The design must ensure that failover does not accidentally open traffic. A
standby should be validated against the same `tests.sh` checks before it is
eligible to become active.

### Cost-benefit decision

HA adds a second gateway, failover infrastructure, spare capacity, monitoring,
licensing or support, and operational testing. It also introduces complexity:
state synchronization and split-brain failures can create new security risks.
For the current phase, the cost and delivery risk were not justified against
the immediate need to remove public exposure and lateral movement.

For Phase 2, the investment is justified if VPN downtime blocks Finance,
remote operations, or recovery activities for longer than the business can
tolerate. The decision should be based on a documented outage cost and target
RTO/RPO. If that cost is low, a tested spare gateway and offline configuration
backup may provide better value than full automatic HA; if it is high, active/
passive HA becomes the preferred control.
