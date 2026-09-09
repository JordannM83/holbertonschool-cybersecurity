# LogiCorp Implementation Plan

## 1. Safety principles

The deployment is phased so that every replacement path is verified before the old path is removed. Changes require an approved maintenance window, a named decision owner, an out-of-band console or hypervisor console, and a recorded known-good configuration.

At every stage:

- keep the original administrative session open;
- apply firewall changes atomically and non-persistently first;
- schedule an automatic restore of the known-good ruleset;
- cancel that restore only after positive validation;
- stop on any unexplained production failure;
- make the smallest temporary exception, record its owner and expiry, and investigate before continuing.

The correct order is:

```text
discover reality -> approve flows -> back up and test rollback -> build zones
-> deploy VPN -> harden SSH -> tunnel FTP -> enforce segmentation
-> enable default deny -> validate monitoring -> make persistent
```

## 2. Step 1 — Discover and approve the production baseline

Before changing anything, verify:

- actual WAN/LAN interface roles, routing, NAT and IPv6 exposure;
- current runtime nftables rules, not only the disabled systemd unit;
- every listener and owning process, especially TCP/21, 22, 3000 and 3001;
- the purpose and owner of `inetd` and every service it exposes;
- FTP authentication, bind address, TLS state and passive-port range;
- database host, address, port, shipping application source and dependencies;
- current VLAN, switch, access-point, DHCP and DNS configuration;
- Suricata runtime status, interfaces, rules, logs and alert delivery;
- individual administrator accounts, authorized keys and `/etc/sudoers.d/debug`;
- all required flows during a representative business period.

Produce and obtain business-owner approval for the final network-object list and flow matrix in `FIREWALL_POLICY.md`. TCP/3000 or TCP/3001 receives no allow rule unless its owner and exact need are documented.

**Validation:** reconcile listening sockets, packet captures where approved, routes and application-owner tests. Confirm that the planned VPN and zone ranges do not overlap any corporate or common remote-client network.

**Rollback:** none; this step is read-only. If the inventory is incomplete, postpone enforcement rather than guessing.

## 3. Step 2 — Back up and prove recovery

Save permissions and checksums with copies of:

- network, switch/VLAN, DHCP, DNS and routing configuration;
- the live nftables ruleset and `/etc/nftables.conf`;
- SSH, WireGuard, vsftpd, inetd, Suricata and sudoers configuration;
- current routes, addresses, listeners and service enablement state.

Prepare a timed recovery job that atomically reloads the known-good firewall ruleset. Test console access and test the recovery job with a harmless temporary rule. Do not use an unconditional firewall flush as rollback because that would expose every service.

**Validation:** restore copies in a test location, validate their syntax, and demonstrate console and timed firewall recovery.

**Rollback:** restore the verified snapshot and reload only the affected service. Use console access if network access is unavailable.

## 4. Step 3 — Build segmentation without moving production

Create the target routed VLANs/zones:

- user LAN: proposed `172.20.10.0/24`;
- Guest: proposed `172.20.20.0/24`;
- DMZ: proposed `172.20.30.0/24`;
- protected database: proposed `172.20.40.0/24`.

Validate address ranges first. Configure gateway subinterfaces, switch trunks/access ports, AP mapping, DHCP scopes and required DNS records. Keep them isolated and do not migrate production hosts yet. The database must be in a separate Layer-2 zone; a firewall cannot isolate same-subnet hosts.

**Validation:** test one non-production host per zone, gateway reachability, DHCP/DNS, VLAN isolation and absence of unintended bridging.

**Rollback:** remove only the new test VLAN assignments and restore the saved switch/gateway configuration. Existing production addressing remains unchanged.

## 5. Step 4 — Deploy and validate WireGuard

Configure `wg0` as `10.10.10.1/24`, listen on UDP/51820, and create one peer and `/32` per managed device. Use the administrator and Finance allocations from `VPN_DESIGN.md`. Install only the narrow client routes required for each role.

Temporarily allow WAN UDP/51820 while retaining existing public SSH and FTP access. Test at least one administrator and one Finance device from an external network.

**Validation:** verify handshake, assigned source address, route scope, administrator SSH, Finance FTP, negative cross-role tests and peer revocation.

**Rollback:** disable `wg0`, remove the temporary UDP/51820 rule and restore the prior ruleset. Do not restrict the old access paths.

## 6. Step 5 — Harden SSH, then remove public SSH

Create and test individual administrator accounts and Ed25519 keys through the VPN. Review `/etc/sudoers.d/debug` and replace excessive privileges with approved least-privilege entries.

Validate SSH configuration syntax, then set:

```text
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
AllowUsers <approved named administrators>
```

Reload SSH without terminating existing sessions. Only after two independent administrators successfully open new VPN-based sessions should WAN TCP/22 be blocked for IPv4 and IPv6.

**Validation:** VPN key login and required sudo actions succeed; root, password, Finance-peer and direct-WAN SSH attempts fail; authentication events are logged.

**Rollback:** use the still-open session or console to restore `sshd_config` and the prior firewall ruleset. Re-enable only the narrow previous administrative path temporarily, with owner and expiry.

## 7. Step 6 — Migrate FTP access behind the VPN

Freeze the verified passive-port range in vsftpd. Add rules permitting only Finance peer `/32`s to the FTP server `/32` on TCP/21 and that passive range. Where supported, bind vsftpd only to its DMZ address.

Test the legacy application through the tunnel before blocking direct WAN access to both the control and passive ports. Record approval of the temporary FTP risk acceptance.

**Validation:** login, upload, download and passive-mode transfers work through a Finance peer; WAN, administrator, Guest and LAN sources fail. Confirm logs and application reconciliation.

**Rollback:** restore the prior FTP bind and rules only long enough to recover business processing. Record the exposure, restrict source addresses as far as possible and retry after correcting the exact failed flow.

## 8. Step 7 — Migrate public/legacy services to the DMZ

Move the FTP service and any approved public service into the DMZ one at a time. TCP/3000, TCP/3001 and inetd services must already have been either disabled or assigned a documented destination, source, port and owner.

Update DNS/NAT only after a parallel test instance or approved cutover test succeeds. Do not provide generic DMZ-to-LAN access.

**Validation:** approved public services work from the expected source; DMZ-to-LAN, DMZ-to-DB and unapproved WAN access fail.

**Rollback:** restore the previous DNS/NAT record and host placement from the saved configuration. Keep the new DMZ path disabled until corrected.

## 9. Step 8 — Move and isolate the database

During an application-approved maintenance window, place the database in the protected DB VLAN. Permit only `SHIPPING_APP` to `DB_SERVER` on the verified TCP `DB_PORT`. Update application configuration or DNS, then test functional and data-integrity checks.

Do not allow Internet, Guest, general LAN, Finance VPN or DMZ access. Administration of the database requires a separately approved, narrow management flow.

**Validation:** shipping transactions and rollback-safe test data succeed; connection tests from every unauthorized zone fail; logs identify allowed and denied sources.

**Rollback:** stop writes, follow the database owner's data-consistency procedure, restore the old address/DNS and prior application configuration, then re-enable the former path. Network rollback must never create two writable database instances.

## 10. Step 9 — Enforce inter-zone and egress default deny

Populate every named object in `FIREWALL_POLICY.md`. Load the complete temporary nftables ruleset atomically with the tested automatic restore armed. Enforce `drop` on INPUT, FORWARD and OUTPUT for IPv4 and IPv6.

Validate in this order:

1. console and existing administrative session;
2. WireGuard and new administrator SSH session;
3. Finance FTP transaction;
4. shipping application/database transaction;
5. approved DMZ services;
6. DNS, NTP, updates and TLS log forwarding;
7. negative tests from WAN, Guest, DMZ, Finance and LAN;
8. explicit checks that TCP/3000 and TCP/3001 are blocked unless approved.

**Rollback:** allow the timed job to reload the known-good ruleset, or reload it from console. Do not flush all rules. Identify the precise missing dependency before another attempt.

## 11. Step 10 — Validate monitoring and alerting

Confirm Suricata monitors the intended boundaries and produces current events. Enable rate-limited nftables deny logs and collect SSH, WireGuard and FTP authentication/activity logs. Forward security logs over TLS to the approved collector, synchronize time, define retention according to company policy, and test alerts for repeated SSH/VPN failures and prohibited inter-zone connections.

**Validation:** generate a controlled event for each source and confirm timestamp, source, destination, rule identifier, receipt by the collector and alert routing to the named responder.

**Rollback:** disable only the faulty sensor rule or forwarding component if it affects performance. Preserve VPN, firewall and segmentation controls, and retain local logs until forwarding is restored.

## 12. Step 11 — Make the validated configuration persistent

Only after the complete test record is approved:

- save the exact validated nftables ruleset;
- enable nftables and WireGuard at boot;
- persist VLAN/routing configuration;
- verify SSH, FTP, Suricata and required services start as designed;
- schedule a reboot in an approved window with console access.

**Validation:** after reboot, repeat all positive and negative tests from Step 9 and verify logging, routes, service binds and default policies.

**Rollback:** boot through console, disable only the faulty persistent component, restore the known-good boot configuration and retest before returning production to service.

## 13. Completion checklist

- [ ] Reality-based interface and service inventory approved
- [ ] TCP/3000, TCP/3001 and inetd disposition documented
- [ ] `/etc/sudoers.d/debug` reviewed
- [ ] Guest, DMZ and database Layer-2 zones isolated
- [ ] VPN works with unique peer `/32`s and narrow routes
- [ ] Root and password SSH disabled after key validation
- [ ] Public SSH blocked over IPv4 and IPv6
- [ ] Finance FTP works only through VPN
- [ ] FTP risk acceptance signed and review date recorded
- [ ] Only the shipping application reaches the database port
- [ ] INPUT, FORWARD and OUTPUT use default deny
- [ ] Suricata and centralized security logs validated
- [ ] Automatic and console rollback tested
- [ ] Persistent configuration survives reboot
