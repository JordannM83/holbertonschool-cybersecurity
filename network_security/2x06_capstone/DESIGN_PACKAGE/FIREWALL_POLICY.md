# LogiCorp Target Firewall Policy

## 1. Scope and principles

The Linux gateway enforces traffic between the WAN, user LAN, Guest, DMZ, protected database and VPN zones. The policy follows these principles:

- default deny on `INPUT`, `FORWARD` and `OUTPUT`;
- allow only documented source, destination, protocol and port combinations;
- separate administration and Finance VPN peers;
- log denied traffic at a rate-limited level;
- never infer interface roles from the obsolete briefing diagram.

The audit found that `eth1` currently owns the default route while `eth0` is link-local. Interface roles, database location, passive FTP range and services on TCP/3000 and TCP/3001 are therefore deployment gates, not assumptions.

## 2. Target objects

The following named objects must be populated from the approved inventory before deployment. Rules must use these objects rather than hard-coded, unverified interface names.

| Object | Target value / source |
|---|---|
| `WAN_IF` | Interface carrying the verified upstream route |
| `LAN_IF` / `LAN_NET` | User LAN interface and subnet |
| `GUEST_IF` / `GUEST_NET` | Guest VLAN/interface and subnet |
| `DMZ_IF` / `DMZ_NET` | DMZ VLAN/interface and subnet |
| `DB_IF` / `DB_NET` | Dedicated protected database VLAN/interface and subnet |
| `VPN_IF` | `wg0` |
| `ADMIN_VPN_IPS` | Individual administrator peer `/32` addresses, `10.10.10.10-49` |
| `FINANCE_VPN_IPS` | Individual Finance peer `/32` addresses, `10.10.10.70-119` |
| `FTP_SERVER` | Verified FTP server address in the DMZ |
| `FTP_PASSIVE_PORTS` | Exact range from the verified vsftpd configuration |
| `SHIPPING_APP` | Verified shipping application address |
| `DB_SERVER` / `DB_PORT` | Verified database address and TCP port |
| `PUBLIC_DMZ_SERVICES` | Approved destination/port pairs; empty unless justified |
| `DNS_RESOLVERS`, `NTP_SERVERS`, `SYSLOG_SERVER` | Approved infrastructure endpoints |

Proposed new zone ranges, subject to overlap validation, are: LAN `172.20.10.0/24`, Guest `172.20.20.0/24`, DMZ `172.20.30.0/24`, and protected DB `172.20.40.0/24`. Existing production addressing may be retained during migration.

## 3. Base policies

| nftables base chain | Hook | Default policy | Purpose |
|---|---|---|---|
| `input` | `input` | `drop` | Protect the gateway itself |
| `forward` | `forward` | `drop` | Enforce inter-zone least privilege |
| `output` | `output` | `drop` | Prevent undocumented gateway-originated traffic |

NAT is not an authorization control. If outbound NAT is required, masquerading is limited to approved internal source networks leaving through `WAN_IF`; VPN-to-internal flows are not masqueraded unless a verified routing limitation requires a documented exception.

## 4. INPUT chain order

| Order | Source / interface | Destination | Protocol | Action | Justification |
|---:|---|---|---|---|---|
| 10 | `ct state invalid` | Gateway | Any | DROP | Discard invalid state before other processing |
| 20 | Loopback | Gateway | Any | ACCEPT | Required local communication |
| 30 | `ct state established,related` | Gateway | Any | ACCEPT | Return traffic for approved sessions |
| 40 | WAN | Gateway | UDP/51820 | ACCEPT, rate-limit new flows | WireGuard endpoint |
| 50 | `ADMIN_VPN_IPS` on `wg0` | Gateway | TCP/22 | ACCEPT | Administrative SSH through VPN only |
| 60 | Approved monitoring subnet, if deployed | Gateway | Exact agent/collector port | ACCEPT | Documented monitoring only |
| 900 | Any | Gateway | Rate-limited log | LOG | Record denied connection attempts |
| 910 | Any | Gateway | Any | DROP | Default deny |

There is no WAN allow rule for TCP/21, TCP/22, TCP/3000 or TCP/3001. IPv4 and IPv6 use equivalent policy; IPv6 must not bypass the controls.

## 5. FORWARD chain order

| Order | Source | Destination | Protocol / port | Action | Justification |
|---:|---|---|---|---|---|
| 10 | `ct state invalid` | Any | Any | DROP | Discard invalid state |
| 20 | Any | Any | `ct state established,related` | ACCEPT | Return traffic for authorized flows |
| 30 | `FINANCE_VPN_IPS` on `wg0` | `FTP_SERVER` | TCP/21 | ACCEPT | Legacy FTP control through VPN |
| 40 | `FINANCE_VPN_IPS` on `wg0` | `FTP_SERVER` | TCP/`FTP_PASSIVE_PORTS` | ACCEPT | Restricted passive data channels |
| 50 | `SHIPPING_APP` | `DB_SERVER` | TCP/`DB_PORT` | ACCEPT | Sole approved database business flow |
| 60 | WAN | `PUBLIC_DMZ_SERVICES` | Approved ports only | ACCEPT | Explicitly published services |
| 70 | Approved internal zones | `DNS_RESOLVERS` | UDP/TCP 53 | ACCEPT | Name resolution where routed |
| 80 | Approved internal zones | `NTP_SERVERS` | UDP/123 | ACCEPT | Time synchronization where required |
| 90 | Approved hosts | `SYSLOG_SERVER` | TCP/6514 | ACCEPT | Authenticated TLS log forwarding |
| 900 | Any | Any | Rate-limited log | LOG | Record denied inter-zone attempts |
| 910 | Any | Any | Any | DROP | Default deny |

The absence of an allow rule blocks:

- WAN to SSH, FTP, database, TCP/3000 and TCP/3001;
- Guest to LAN, DMZ, database and VPN networks;
- Finance VPN to SSH, database and other LAN resources;
- DMZ to LAN and protected database;
- general LAN access to the database;
- lateral traffic routed between user segments.

Layer-2 separation through VLANs is mandatory because gateway rules cannot filter traffic between hosts on the same broadcast segment.

## 6. OUTPUT chain order

| Order | Source | Destination | Protocol / port | Action | Justification |
|---:|---|---|---|---|---|
| 10 | Gateway | Loopback | Any | ACCEPT | Local operation |
| 20 | Gateway | Any | `ct state established,related` | ACCEPT | Return traffic |
| 30 | Gateway | `DNS_RESOLVERS` | UDP/TCP 53 | ACCEPT | DNS resolution |
| 40 | Gateway | `NTP_SERVERS` | UDP/123 | ACCEPT | Clock synchronization |
| 50 | Gateway | Approved update repositories/proxy | TCP/443 | ACCEPT | Security updates |
| 60 | Gateway | `SYSLOG_SERVER` | TCP/6514 | ACCEPT | TLS log forwarding |
| 70 | Gateway | WireGuard peer endpoints | UDP/51820 | ACCEPT | VPN replies and keepalives |
| 900 | Gateway | Any | Rate-limited log | LOG | Detect undocumented egress requirements |
| 910 | Gateway | Any | Any | DROP | Default-deny egress |

DHCP or other gateway services may be added only after their exact interface, endpoints and ports are documented.

## 7. Host hardening tied to the policy

The network policy is not sufficient by itself:

- set `PermitRootLogin no`;
- validate key-based access for every administrator, then set `PasswordAuthentication no`;
- retain individual named accounts and controlled `sudo` elevation;
- review `/etc/sudoers.d/debug` with privileged access and remove excessive grants;
- identify TCP/3000 and TCP/3001 before enforcement, then add only narrowly scoped rules if approved;
- audit `inetd` and disable unused services;
- restrict vsftpd to the required interface/address when supported;
- verify Suricata runtime status, monitored interfaces, rules and alert delivery.

## 8. Ordering rationale and change gate

Rules are evaluated per chain, not as one global list. Each chain handles invalid state first, permits established traffic, adds narrow business exceptions, logs at a controlled rate, and ends in default deny.

The production ruleset must not be activated until interface roles, IP objects, FTP passive ports, the database flow, TCP/3000 and TCP/3001, IPv6 exposure and monitoring endpoints are verified. Apply the temporary ruleset atomically with automatic restoration of the known-good ruleset if validation is not acknowledged.
