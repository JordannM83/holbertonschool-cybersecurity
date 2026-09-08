# LogiCorp Technical Assessment

## 1. Scope

This technical assessment was performed on the LogiCorp Linux Gateway in order to compare the live environment with the documentation provided in the Briefing Pack.

The audit covers:

- System information
- Network topology
- Network attack surface
- Security controls
- Local user accounts
- SSH configuration and keys
- Running and enabled services
- Scheduled tasks
- Differences between documentation and reality

Some service-management information could not be retrieved because the audited environment is not currently running `systemd` as PID 1.

---

# 2. System Information

## 2.1 Operating System

- **OS:** Ubuntu Linux
- **Distribution:** Ubuntu 22.04.5
- **Kernel Version:** 6.1.77
- **Architecture:** x86_64

## 2.2 Host Information

- **Hostname:** `fae89e193ec543dc9011f1a80a9935cd-2377118072`
- **Uptime:** 11:30:17 / 3:30

## 2.3 Notes

The hostname differs significantly from what would normally be expected from a manually configured production gateway and may indicate that the assessment environment is running inside a containerized or dynamically provisioned infrastructure.

This must be confirmed before drawing conclusions about the production architecture.

---

# 3. Network Topology

## 3.1 Network Interfaces

### Loopback Interface

- **Interface:** `lo`
- **Status:** Unknown
- **MAC Address:** `00:00:00:00:00:00`
- **IP Address:** `127.0.0.1`
- **CIDR:** `127.0.0.1/8`
- **Network:** `127.0.0.0/8`
- **Role:** Local loopback

### Interface eth0

- **Interface:** `eth0`
- **Status:** UP
- **MAC Address:** `0a:58:a9:fe:ac:02`
- **IP Address:** `169.254.172.2`
- **CIDR:** `169.254.172.2/22`
- **Network:** `169.254.172.0/22`
- **Role:** Unknown

The `169.254.0.0/16` address range is link-local. Based on the observed routing table, `eth0` does not appear to be the primary Internet-facing interface described in the documentation.

### Interface eth1

- **Interface:** `eth1`
- **Status:** UP
- **MAC Address:** `0a:87:55:62:40:2d`
- **IP Address:** `10.42.48.143`
- **CIDR:** `10.42.48.143/16`
- **Network:** `10.42.0.0/16`
- **Role:** Primary routed interface / role to be confirmed

The default route uses this interface, which suggests that `eth1` currently provides upstream connectivity.

---

## 3.2 IP Address Summary

| Interface | IP Address | CIDR | Network | Observed Role |
|---|---|---|---|---|
| `lo` | 127.0.0.1 | /8 | 127.0.0.0/8 | Loopback |
| `eth0` | 169.254.172.2 | /22 | 169.254.172.0/22 | Link-local / Unknown |
| `eth1` | 10.42.48.143 | /16 | 10.42.0.0/16 | Primary routed interface |

---

## 3.3 Routing Table

### Default Gateway

- **Gateway:** `10.42.0.1`
- **Interface:** `eth1`

### Observed Routes

| Destination | Gateway | Interface | Notes |
|---|---|---|---|
| `0.0.0.0/0` | `10.42.0.1` | `eth1` | Default route |
| `10.42.0.0/16` | Direct | `eth1` | Directly connected network |
| `169.254.169.254` | Direct / Unknown | Unknown | Link-local destination |
| `169.254.170.2` | `169.254.172.1` | `eth0` | Routed through link-local gateway |
| `169.254.172.1` | Direct | `eth0` | Directly connected |

---

## 3.4 ARP / Neighbor Table

| IP Address | MAC Address | Interface | State |
|---|---|---|---|
| `10.42.0.1` | `0a:b0:93:32:a4:d0` | `eth1` | REACHABLE |

Only one neighbor was recorded during the audit.

---

# 4. Attack Surface

## 4.1 Listening TCP Ports

| Port | Bind Address | Protocol | Process | Service | Exposure |
|---|---|---|---|---|---|
| 21 | `*` | TCP | Not identified | FTP | All available interfaces |
| 22 | `0.0.0.0` | TCP | Not identified | SSH | All IPv4 interfaces |
| 22 | `[::]` | TCP | Not identified | SSH | All IPv6 interfaces |
| 3000 | `0.0.0.0` | TCP | Not identified | Unknown | All IPv4 interfaces |
| 3001 | `0.0.0.0` | TCP | Not identified | Unknown | All IPv4 interfaces |

## 4.2 UDP Ports

No listening UDP ports were observed in the supplied audit results.

---

## 4.3 Network-Facing Services

### SSH

- **Protocol:** TCP
- **Port:** 22
- **Bind Address:** `0.0.0.0` and `[::]`
- **Process:** Not identified
- **Authentication:** Password and public-key authentication enabled
- **Encryption:** Yes
- **Network Exposure:** Listening on all available interfaces
- **Internet Reachability:** Not independently verified

### FTP

- **Software:** `vsftpd`
- **Protocol:** FTP
- **Port:** 21/TCP
- **Bind Address:** `*`
- **Network Exposure:** Listening on all available interfaces
- **Authentication:** Not verified
- **Encryption/TLS:** Not verified from live configuration

### Unknown Application — Port 3000

- **Protocol:** TCP
- **Port:** 3000
- **Bind Address:** `0.0.0.0`
- **Process:** Not identified
- **Application:** Unknown
- **Exposure:** All IPv4 interfaces

### Unknown Application — Port 3001

- **Protocol:** TCP
- **Port:** 3001
- **Bind Address:** `0.0.0.0`
- **Process:** Not identified
- **Application:** Unknown
- **Exposure:** All IPv4 interfaces

The services running on ports `3000` and `3001` are undocumented and require further investigation.

---

# 5. Security Controls

## 5.1 Firewall

### Observed Information

An `nftables` systemd unit exists:

- **Firewall Technology Detected:** nftables
- **nftables Unit State:** Disabled
- **Vendor Preset:** Enabled

However, service status could not be queried because:

```text
System has not been booted with systemd as init system (PID 1).
Can't operate.
Failed to connect to bus: Host is down
```

### Assessment

- **Firewall Installed:** Yes, nftables components appear to be present
- **Firewall Service Enabled:** No
- **Firewall Currently Active:** Not conclusively verified
- **Default Input Policy:** Unknown
- **Default Output Policy:** Unknown
- **Default Forward Policy:** Unknown
- **Existing Rules:** Not recorded
- **Persistence:** nftables service disabled

The documentation states that no firewall is active. The observed disabled `nftables` service is consistent with this description, but the actual runtime ruleset must be checked directly before confirming that no firewall rules are loaded.

---

## 5.2 SELinux

The SELinux management command was not found.

- **Installed:** Not detected
- **Enabled:** No evidence
- **Mode:** Not available
- **Assessment:** SELinux does not appear to be installed or available in the current environment.

---

## 5.3 AppArmor

The AppArmor service status could not be checked using `systemctl` because systemd is not running as PID 1.

- **Installed:** Unknown
- **Enabled:** Unknown
- **Profiles Loaded:** Unknown
- **Profiles Enforcing:** Unknown
- **Profiles Complaining:** Unknown

Further verification using AppArmor-specific tools is required.

---

# 6. User Accounts

## 6.1 Interactive / Local Users

| Username | UID | Home Directory | Shell | Type |
|---|---:|---|---|---|
| `student` | 1000 | `/home/student` | `/bin/bash` | Interactive user |
| `nobody` | 65534 | `/nonexistent` | `/usr/sbin/nologin` | System account |

The only normal interactive user identified from the provided results is `student`.

---

## 6.2 Relevant Groups

The following security-relevant groups exist:

- `sudo`
- `adm`
- `shadow`
- `ssh`
- `ftp`
- `telnetd`
- `www-data`
- `ssl-cert`

The `sudo` group contains no users directly listed in `/etc/group`:

```text
sudo:x:27:
```

This does not prove that no sudo privileges exist because permissions can also be defined directly in `/etc/sudoers` or `/etc/sudoers.d/`.

---

## 6.3 sudo Configuration

The main sudo configuration could not be read:

```text
cat: /etc/sudoers: Permission denied
```

The following directory exists:

```text
/etc/sudoers.d/
```

Files identified:

```text
README
debug
```

The file:

```text
/etc/sudoers.d/debug
```

is particularly important and should be reviewed because custom sudo permissions may be defined inside it.

Current results:

- **sudo Group:** Present
- **Users directly listed in sudo group:** None
- **Custom sudoers directory:** Present
- **Custom file:** `/etc/sudoers.d/debug`
- **NOPASSWD Rules:** Unknown
- **Restricted Commands:** Unknown
- **Excessive Privileges:** Not verified

---

# 7. SSH Security Assessment

## 7.1 SSH Configuration

Observed configuration:

```text
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
AllowUsers student
```

### Effective Assessment

- **SSH Port:** 22/TCP
- **Listening:** Yes
- **Bind Address:** All IPv4 and IPv6 interfaces
- **PermitRootLogin:** Yes
- **Password Authentication:** Yes
- **Public Key Authentication:** Yes
- **AllowUsers:** `student`
- **AllowGroups:** Not identified
- **PermitEmptyPasswords:** Not identified

### Important Finding

Although:

```text
PermitRootLogin yes
```

is configured, the presence of:

```text
AllowUsers student
```

appears to restrict SSH access to the `student` account.

Therefore, the documentation stating that root is directly accessible through SSH may no longer accurately reflect the effective configuration.

However, the configuration remains unsafe because enabling `PermitRootLogin yes` creates unnecessary risk and could become exploitable if the `AllowUsers` restriction is later changed or removed.

---

## 7.2 SSH Authorized Keys

One Ed25519 public key was identified:

```text
ssh-ed25519 AAAA... 11457@holbertonstudents.com
```

Assessment:

- **Authorized Key Present:** Yes
- **Number of observed keys:** 1
- **Key Type:** Ed25519
- **Associated identifier:** `11457@holbertonstudents.com`
- **Suspicious Key:** None identified from the supplied evidence

The full public key should not be reproduced in a final security report unless necessary.

---

# 8. Running and Enabled Services

## 8.1 Important Limitation

The supplied service listing represents **systemd unit-file configuration**, not necessarily the current runtime state.

Because systemd is not running as PID 1, the actual running state of every service cannot be determined using `systemctl`.

Network listeners identified through `ss`, however, prove that some network services are currently active.

---

## 8.2 Enabled Services

The following services are configured to start automatically:

| Service | Enabled | Network-Relevant | Notes |
|---|---|---|---|
| `cron.service` | Yes | No | Scheduled tasks |
| `inetd.service` | Yes | Potentially | Legacy network service dispatcher |
| `networkd-dispatcher.service` | Yes | No | Network event dispatcher |
| `ssh.service` | Yes | Yes | SSH remote administration |
| `suricata.service` | Yes | Yes | IDS/IPS monitoring |
| `systemd-resolved.service` | Yes | Network-related | DNS resolution |
| `systemd-timesyncd.service` | Yes | Network-related | Time synchronization |
| `vsftpd.service` | Yes | Yes | FTP server |

---

## 8.3 Security-Relevant Service States

### SSH

- **Configured at boot:** Enabled
- **Observed listener:** Yes
- **Port:** 22/TCP
- **Bind:** All interfaces

### FTP / vsftpd

- **Configured at boot:** Enabled
- **Observed listener:** Yes
- **Port:** 21/TCP
- **Bind:** All interfaces

### Suricata

- **Configured at boot:** Enabled
- **Runtime state:** Not verified

The presence of Suricata is significant because no intrusion detection or monitoring capability was mentioned in the original documentation.

### Fail2ban

The unit-file information indicates:

- **Unit state:** Disabled
- **Vendor preset:** Enabled
- **Runtime state:** Not verified

### nftables

- **Unit state:** Disabled
- **Vendor preset:** Enabled
- **Runtime rules:** Not verified

### inetd

- **Configured at boot:** Enabled

Because `inetd` is a legacy network service dispatcher, its configuration should be reviewed to determine which services it exposes.

---

# 9. Database Assessment

The documentation describes a central database used by the shipping application.

However, no obvious database listener was observed in the supplied TCP listening-port results.

In particular, no standard listeners were observed on:

- MySQL / MariaDB: `3306/TCP`
- PostgreSQL: `5432/TCP`

Current assessment:

- **Database Status:** Not identified locally
- **Database Software:** Unknown
- **Port:** Not identified
- **Bind Address:** Unknown
- **Network Exposure:** Unknown

Possible explanations include:

- The database is hosted on another machine.
- The database uses a non-standard port.
- The database only exposes a local Unix socket.
- The database is running inside another isolated environment.
- The documentation is inaccurate.

Further investigation is required.

---

# 10. VPN Assessment

No VPN interface or VPN service was identified in the supplied audit results.

- **VPN Status:** No VPN confirmed
- **Technology:** Unknown / None identified
- **Interface:** None identified
- **VPN Port:** None identified
- **VPN Network:** None identified

This is important because the target architecture requires secure remote access and protection of the legacy Accounting FTP workflow.

---

# 11. Scheduled Tasks

## 11.1 Student Crontab

The `student` account has no personal crontab:

```text
no crontab for student
```

---

## 11.2 System Cron Jobs

The following default system tasks were identified:

| Schedule | User | Command | Purpose |
|---|---|---|---|
| `17 * * * *` | root | `run-parts /etc/cron.hourly` | Run hourly jobs |
| `25 6 * * *` | root | `run-parts /etc/cron.daily` | Run daily jobs |
| `47 6 * * 7` | root | `run-parts /etc/cron.weekly` | Run weekly jobs |
| `52 6 1 * *` | root | `run-parts /etc/cron.monthly` | Run monthly jobs |

No suspicious custom cron task was identified from the supplied information.

---

## 11.3 Cron Directories

### `/etc/cron.hourly`

Contents not recorded.

### `/etc/cron.daily`

Contents not recorded.

### `/etc/cron.weekly`

Contents not recorded.

### `/etc/cron.monthly`

Contents not recorded.

### `/etc/cron.d`

Contents not fully recorded.

Additional inspection is required before confirming that no custom scheduled jobs exist.

---

## 11.4 systemd Timers

systemd timers could not be queried because the environment is not running systemd as PID 1.

```text
System has not been booted with systemd as init system (PID 1).
Can't operate.
Failed to connect to bus: Host is down
```

- **Timers identified:** Unknown
- **Audit status:** Incomplete

---

# 12. Documentation vs Reality

## 12.1 System

### Documented

The environment is described as a single Linux Gateway that has evolved over approximately ten years.

### Observed

The audited host is:

- Ubuntu 22.04.5
- Kernel 6.1.77
- x86_64
- Hostname: `fae89e193ec543dc9011f1a80a9935cd-2377118072`

### Discrepancy

No major operating-system discrepancy can be established because the original documentation did not specify an exact Linux distribution or version.

However, the dynamically generated hostname suggests that the assessed environment may differ from the physical architecture represented in the documentation.

---

## 12.2 Network Architecture

### Documented

The Briefing Pack states:

```text
CURRENT: FLAT NETWORK.
Everything is on the same subnet (192.168.1.x).
```

The supplied diagram identifies:

```text
eth0 = WAN
eth1 = LAN
```

### Observed

The live system contains:

```text
eth0 = 169.254.172.2/22
eth1 = 10.42.48.143/16
```

The default route is:

```text
default via 10.42.0.1 dev eth1
```

No `192.168.1.x` address was observed.

### Discrepancy

This is a major documentation discrepancy.

The documented `192.168.1.x` network does not match the live host.

Additionally, `eth1`, documented as the LAN-facing interface, currently carries the default route and therefore appears to provide upstream connectivity.

`eth0`, documented as WAN, currently uses a link-local `169.254.x.x` network.

The actual network topology differs substantially from the supplied diagram and must be rediscovered before implementing firewall or segmentation rules.

---

## 12.3 Firewall

### Documented

```text
CURRENT: No Firewall active.
TARGET: Default Deny.
```

### Observed

An `nftables` service exists but is disabled.

No active firewall rules were documented in the supplied results.

### Discrepancy

The observation broadly supports the documentation, but the active runtime ruleset still needs to be checked directly before confirming that no filtering rules exist.

---

## 12.4 SSH

### Documented

```text
SSH open to the entire Internet.
Root enabled.
```

### Observed

SSH listens on:

```text
0.0.0.0:22
[::]:22
```

Configuration includes:

```text
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
AllowUsers student
```

### Discrepancy

SSH is definitely listening on all host interfaces, which is consistent with excessive network exposure.

However, direct Internet accessibility cannot be confirmed solely from the local listening address.

Additionally, although `PermitRootLogin yes` exists, `AllowUsers student` appears to restrict SSH login to `student`.

Therefore, the documentation claiming that root can directly authenticate through SSH may be outdated.

---

## 12.5 FTP

### Documented

```text
FTP server running in cleartext.
```

### Observed

A service is listening on:

```text
*:21
```

and:

```text
vsftpd.service
```

is configured to start automatically.

### Discrepancy

The presence of FTP is confirmed and therefore matches the documentation.

However, the live FTP TLS configuration was not recorded, so cleartext-only operation has not yet been independently verified from the server configuration.

---

## 12.6 Database

### Documented

A critical central database supports the company's shipping software.

The diagram places the database on the same internal network as:

- Office computers
- Finance systems
- Guest WiFi

### Observed

No standard database listener was identified in the recorded listening-port output.

### Discrepancy

The documented database cannot currently be located from the collected data.

Its actual host, network, port and exposure remain unknown.

This is a significant discovery gap because database isolation is one of the client's primary security requirements.

---

## 12.7 Services

### Documented

The documentation mainly identifies:

- SSH
- FTP
- Database services

### Observed

Additional components were identified:

- TCP/3000
- TCP/3001
- Suricata
- inetd
- Fail2ban installation/unit
- nftables installation/unit

### Discrepancy

The environment contains services and security components that were not described in the Briefing Pack.

The applications listening on TCP ports `3000` and `3001` are particularly important because they expand the attack surface and have not yet been identified.

---

# 13. Discrepancy Summary

| ID | Area | Documentation | Reality | Security Impact |
|---|---|---|---|---|
| D-01 | Network | Flat `192.168.1.x` network | `10.42.0.0/16` and link-local `169.254.172.0/22` observed | Critical – firewall design based on old documentation could break connectivity |
| D-02 | Interfaces | `eth0` WAN / `eth1` LAN | Default route currently uses `eth1`; `eth0` is link-local | Critical – interface trust roles appear incorrect |
| D-03 | SSH | Root SSH exposed to Internet | SSH listens globally, but `AllowUsers student` restricts allowed username | High – documentation does not fully match effective SSH policy |
| D-04 | FTP | FTP service exists | FTP/21 and vsftpd confirmed | High – legacy service remains network exposed |
| D-05 | Database | Database on internal flat network | Database listener not identified | Critical – critical asset location currently unknown |
| D-06 | Services | SSH, FTP and DB primarily documented | TCP/3000 and TCP/3001 also listening | High – undocumented attack surface |
| D-07 | Monitoring | No monitoring documented | Suricata is configured/enabled | Medium – existing security control missing from documentation |
| D-08 | Firewall | No firewall active | nftables installed but unit disabled | High – runtime filtering must still be verified |
| D-09 | Scheduled Tasks | Not documented | Standard cron tasks present | Low – documentation incomplete |
| D-10 | Administration | sudo model undocumented | `/etc/sudoers.d/debug` exists but could not be read | High – privileged-access configuration remains unknown |

---

# 14. Additional Findings

## Finding 1 — Undocumented TCP/3000 Service

- **Category:** Attack Surface
- **Observation:** A process is listening on `0.0.0.0:3000`.
- **Security Impact:** The application is reachable through all IPv4 interfaces and increases the host's attack surface.
- **Process:** Unknown
- **Severity:** High
- **Required Action:** Identify the process and determine whether external access is required.

---

## Finding 2 — Undocumented TCP/3001 Service

- **Category:** Attack Surface
- **Observation:** A process is listening on `0.0.0.0:3001`.
- **Security Impact:** An undocumented network service may expose an unnecessary attack path.
- **Process:** Unknown
- **Severity:** High
- **Required Action:** Identify the process and business purpose.

---

## Finding 3 — SSH Password Authentication Enabled

- **Category:** Remote Access
- **Observation:** `PasswordAuthentication yes`
- **Security Impact:** Password-based SSH authentication increases exposure to credential attacks.
- **Severity:** High
- **Required Action:** Evaluate migration toward key-based authentication through the future secure remote-access architecture.

---

## Finding 4 — PermitRootLogin Enabled

- **Category:** Access Control
- **Observation:** `PermitRootLogin yes`
- **Security Impact:** Direct root SSH authentication is unnecessarily permitted by configuration.
- **Compensating Control:** `AllowUsers student` currently appears to restrict login to the `student` user.
- **Severity:** High
- **Required Action:** Explicitly disable root SSH login.

---

## Finding 5 — FTP Listens on All Interfaces

- **Category:** Legacy Protocol / Encryption
- **Observation:** FTP listens on `*:21`.
- **Security Impact:** The legacy service is reachable through every interface on which routing and filtering permit access.
- **Severity:** High
- **Required Action:** Restrict FTP to authorized sources, preferably through the planned VPN.

---

## Finding 6 — Security Monitoring Component Present

- **Category:** Monitoring
- **Observation:** `suricata.service` is configured as enabled.
- **Security Impact:** This may provide an existing IDS/IPS capability that was not documented.
- **Severity:** Informational / Positive Control
- **Required Action:** Verify whether Suricata is actually running and review its interfaces, rules and logging configuration.

---

## Finding 7 — Legacy inetd Enabled

- **Category:** Attack Surface
- **Observation:** `inetd.service` is configured to start automatically.
- **Security Impact:** inetd can expose additional legacy network services that may not be visible in the project documentation.
- **Severity:** Medium
- **Required Action:** Audit `/etc/inetd.conf` and related configuration files.

---

## Finding 8 — Unknown sudoers Configuration

- **Category:** Privilege Management
- **Observation:** `/etc/sudoers.d/debug` exists but could not be inspected.
- **Security Impact:** The file could contain custom or excessive administrative privileges.
- **Severity:** High
- **Required Action:** Review it with appropriate privileges.

---

# 15. Audit Limitations

The following information remains incomplete:

- System uptime
- Runtime nftables ruleset
- Effective AppArmor status
- Full sudo configuration
- Contents of `/etc/sudoers.d/debug`
- Complete authorized SSH keys for all users
- Process names and PIDs for TCP ports 21, 22, 3000 and 3001
- FTP TLS configuration
- FTP authentication configuration
- Exact database location and configuration
- Actual Suricata runtime status
- inetd-exposed services
- Cron directory contents
- systemd timers
- Actual external Internet reachability
- Physical network topology

These items should be collected before remediation begins.

---

# 16. Overall Assessment

The live audit confirms several of the security concerns described in the Briefing Pack, including a network-facing FTP service, globally bound SSH service and lack of confirmed active firewall enforcement.

However, the most important discovery is that the documented network topology is inaccurate. The expected `192.168.1.x` network was not found, the documented WAN/LAN interface roles do not match the observed routing configuration, and the critical database has not yet been located.

The environment also contains undocumented services on TCP ports `3000` and `3001`, an enabled Suricata unit, an enabled inetd service and a custom sudoers file.

No remediation or firewall deployment should therefore be based solely on the original diagram. The actual service dependencies, interface roles and database location must first be validated to avoid disrupting production.