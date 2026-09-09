# LogiCorp VPN Design

## 1. Objective and topology

WireGuard terminates on the Linux gateway and is the only remote entry point for administration and legacy Finance FTP access.

```text
Administrator device -- WireGuard/UDP 51820 --> Gateway wg0 -- SSH/22 --> Gateway
Finance device       -- WireGuard/UDP 51820 --> Gateway wg0 -- FTP/21 + passive range --> DMZ FTP server
```

The tunnel authenticates a device; authorization is separately enforced by peer-specific addresses and the firewall. Establishing a VPN tunnel never grants unrestricted LAN access.

Before deployment, confirm the public endpoint, NAT/port-forward path and actual WAN interface. The audit indicates that the documented `eth0`/`eth1` roles are unreliable.

## 2. Addressing

The proposed tunnel subnet is `10.10.10.0/24`, subject to a route-overlap check against headquarters, home networks and cloud networks.

| Purpose | Allocation |
|---|---|
| Gateway `wg0` | `10.10.10.1/24` |
| Administrator peers | Individual `/32`s from `10.10.10.10` through `10.10.10.49` |
| Finance peers | Individual `/32`s from `10.10.10.70` through `10.10.10.119` |
| Reserved | Remaining addresses |

Each device receives a unique key pair and one unique `/32`. Addresses are never shared, and the gateway peer configuration binds each public key to only its assigned tunnel `/32` through `AllowedIPs`.

If overlap is found, a non-conflicting RFC1918 subnet must be approved before rollout.

## 3. WireGuard parameters

| Parameter | Design |
|---|---|
| Gateway listen port | UDP/51820 |
| Gateway endpoint | Approved public FQDN or IP, confirmed during discovery |
| Client `AllowedIPs` | Only required target prefixes; no `0.0.0.0/0` by default |
| Administrator route | `10.10.10.1/32` for gateway SSH; other hosts require approval |
| Finance route | Exact `/32` of `FTP_SERVER` only |
| Persistent keepalive | 25 seconds only for peers behind NAT when required |
| DNS | No DNS pushed unless an internal name is required |
| MTU | Platform default, tested and adjusted if path MTU requires it |
| IPv6 | Disabled for the tunnel or protected by equivalent routes and rules |

Split tunneling is used so only authorized corporate destinations enter the VPN.

## 4. Access-control matrix

| Role | Gateway SSH | DMZ FTP | Passive FTP | Database | LAN | Guest | Other DMZ |
|---|---:|---:|---:|---:|---:|---:|---:|
| Administrator | Allow TCP/22 | Deny | Deny | Deny by default | Deny by default | Deny | Deny |
| Finance | Deny | Allow TCP/21 | Allow verified range | Deny | Deny | Deny | Deny |

Any additional administrator target must identify the owner, source peer `/32`, destination `/32`, protocol, port, justification and expiry date.

## 5. Peer lifecycle

- Provision one configuration per managed device; never transmit private keys through email or tickets.
- Record owner, device, role, assigned `/32`, public-key fingerprint, issue date and approval.
- Protect client private keys with operating-system storage and device access controls.
- Revoke lost, retired or unauthorized devices immediately by removing the peer and reloading WireGuard.
- Review the peer inventory quarterly and after personnel changes.
- Rotate a peer key after suspected compromise and during device replacement.
- Monitor handshakes and firewall events; a WireGuard handshake alone is not proof of user identity.

WireGuard does not provide native user MFA. Where available, require MFA for device access and SSH, and use passphrase-protected administrator SSH keys.

## 6. SSH controls through VPN

After VPN access and individual administrator keys are tested:

```text
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
AllowUsers <approved named administrators>
```

Keep individual accounts and use `sudo` only for approved commands or roles. Review `/etc/sudoers.d/debug` before relying on the privilege model. Public TCP/22 remains blocked for IPv4 and IPv6.

## 7. Legacy FTP through VPN

The Finance application continues to use FTP, but only after its device establishes WireGuard. Firewall authorization is restricted to the Finance peer `/32`, the verified FTP server `/32`, TCP/21 and the exact configured passive range.

FTP remains cleartext between the gateway and server if the server is separate. The FTP server is therefore placed in the DMZ, the internal segment is controlled, and the residual risk remains formally accepted until migration.

## 8. Validation criteria

- Every peer receives its assigned address and no other address is accepted for that key.
- Administrator VPN SSH succeeds; Finance VPN SSH fails.
- Finance FTP login, upload, download and passive transfer succeed.
- Finance access to LAN, database and other DMZ services fails.
- Direct WAN access to SSH, FTP, passive FTP, TCP/3000 and TCP/3001 fails over IPv4 and IPv6.
- Revoking a test peer prevents new authorized traffic.
- Routes do not overlap client or corporate networks.
- VPN handshake and denied-flow events reach monitoring.
