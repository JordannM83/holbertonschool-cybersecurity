# Nexus Financial Defensive Architecture — Final Audit Report

**Scope:** `security_concepts/3x06_defensive_architect/`
**Assessment:** Self-audit of the policy and technical controls
**Status:** The commands below describe the evidence expected after running the scripts on an Ubuntu 20.04+ test host. They are not presented as live production evidence.

## Executive summary

The implementation addresses the original P0 risks: public PostgreSQL access, shared
administrator SSH keys, excessive privilege, missing central logs, and weak incident
readiness. The controls are implemented through the policy documents and four technical
scripts: hardening, RBAC, network defense, and logging.

## 1. Verification commands and expected output

### Script integrity

**Verification command**

```bash
cd security_concepts/3x06_defensive_architect
for script in technical/*.sh; do bash -n "$script" && echo "PASS: $script"; done
git diff --check -- technical policy audit
```

**Expected output**

```text
PASS: technical/hardening.sh
PASS: technical/logging_setup.sh
PASS: technical/network_defense.sh
PASS: technical/rbac_setup.sh
```

No syntax or whitespace errors should be reported.

### SSH hardening

**Verification command**

```bash
sshd -T | grep -E 'permitrootlogin|passwordauthentication|kbdinteractiveauthentication|allowgroups'
```

**Expected output**

```text
permitrootlogin no
passwordauthentication no
kbdinteractiveauthentication no
allowgroups nexus-ssh
```

### RBAC and home directories

**Verification command**

```bash
getent group devs ops auditors
id sarah
id dave
stat -c '%U:%G %a %n' /home/sarah /home/dave /home/developer
visudo -cf /etc/sudoers.d/nexus-rbac
sudo -l -U sarah
sudo -l -U dave
```

**Expected output**

```text
devs:x:<gid>:developer,sarah
ops:x:<gid>:sarah
auditors:x:<gid>:dave
uid=<uid>(sarah) ... groups=... devs,ops
uid=<uid>(dave) ... groups=... auditors
sarah:sarah 700 /home/sarah
dave:dave 700 /home/dave
developer:developer 700 /home/developer
parsed OK
Sarah: approved Nginx restart/status commands only
Dave: /usr/local/sbin/nexus-nginx-logs only
```

Negative tests must fail:

```bash
sudo -u dave sudoedit /etc/nginx/nginx.conf
sudo -u dave sudo systemctl restart nginx
```

Expected result: `Sorry, user dave is not allowed to execute ...`.

### Network segmentation

**Verification command**

```bash
WEB_SERVER_PRIVATE_IP=10.20.1.10 \
BASTION_HOST_IP=10.20.0.10 \
sudo technical/network_defense.sh
sudo ufw status numbered
```

**Expected output**

```text
[ 1] 5432/tcp ALLOW IN 10.20.1.10
[ 2] 22/tcp   ALLOW IN 10.20.0.10
Status: active
Default: deny (incoming), deny (routed), allow (outgoing)
```

There must be no PostgreSQL rule from `Anywhere`, `0.0.0.0/0`, or an unapproved source.

### Central logging

**Verification command**

```bash
CENTRAL_LOG_SERVER_IP=10.20.0.20 sudo technical/logging_setup.sh
rsyslogd -N1
grep -E '\*\.crit|authpriv\.\*|@@10\.20\.0\.20:514' \
    /etc/rsyslog.d/60-nexus-central.conf
```

**Expected output**

```text
rsyslogd: End of config validation run. Bye.
critical and authentication forwarding rules present
```

The central collector must receive a controlled authentication event. TCP forwarding and
the disk-backed queue must retry when the collector is temporarily unavailable.

### Auditd

**Verification command**

```bash
auditctl -s | grep enabled
auditctl -l | grep -E 'passwd|shadow|sudoers|sshd_config|privileged_commands'
```

**Expected output**

```text
enabled 2
-w /etc/passwd -p wa -k identity_changes
-w /etc/shadow -p wa -k identity_changes
-w /etc/sudoers -p wa -k privilege_changes
-w /etc/ssh/sshd_config -p wa -k ssh_changes
-a always,exit ... -k privileged_commands
```

`enabled 2` proves audit configuration is immutable until reboot.

### Service and response readiness

**Verification command**

```bash
systemctl is-active fail2ban apparmor auditd rsyslog
test -r policy/incident_response_plan.md && echo 'PASS: incident playbook present'
```

**Expected output**

```text
active
active
active
active
PASS: incident playbook present
```

The cloud owner must attach a successful database restore, backup encryption/versioning,
security-group export, and central-log receipt. These cannot be proven by repository files.

## 2. Self-assessment

### Strengths

- P0 risks are mapped to specific controls and verification commands.
- Individual groups and limited sudo commands replace shared administrator access.
- PostgreSQL is restricted to the private web server and SSH to the bastion.
- Audit rules monitor identity, authorization, SSH, scheduled tasks, service configuration,
  and human-root command execution.
- The incident playbook gives Sarah and Dave an ordered response that preserves evidence.

### Gaps and residual risk

- This is a self-audit; live host output, cloud exports, backup restore proof, and central
  collector evidence still need to be attached.
- Scripts require correct production values for the web server, bastion, and log collector.
  Incorrect values can block access, so execution requires a maintenance window and console
  recovery path.
- UFW does not replace cloud security groups, VLANs, WAF/rate limiting, VPN, or bastion controls.
- Physical security depends on the co-working provider and the procedures in the physical plan.
- Central logs still require protected retention, time synchronization, alerting, and access review.
- Demo users must be replaced or integrated with production identity, MFA, secrets management,
  and joiner/mover/leaver processes.

### Overall rating

**Partially effective; remediation required before final production sign-off.** The design and
automation materially reduce the P0 risks, but the auditor should require live evidence that
public `5432` is closed, bastion-only SSH works, Sarah and Dave permissions behave correctly,
logs reach the central server, audit immutability is active, and backups restore successfully.

## 3. Auditor sign-off checklist

- [ ] Four technical scripts pass syntax and controlled execution tests.
- [ ] PostgreSQL security group and UFW output show no public `5432` access.
- [ ] SSH is reachable only through the bastion and root/password login fails.
- [ ] Sarah can restart Nginx; Dave can read logs but cannot edit configuration.
- [ ] Central collector receives critical and authentication logs.
- [ ] `auditctl -s` reports `enabled 2` and privileged commands generate events.
- [ ] A clean database restore has been completed and reconciled.
- [ ] Physical access, training, incident contacts, and evidence retention are verified.
