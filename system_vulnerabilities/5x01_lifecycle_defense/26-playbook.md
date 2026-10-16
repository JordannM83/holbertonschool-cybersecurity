# Patch Management Incident Response Procedure

**Audience:** On-call engineers, platform operations, security, and service owners  
**Trigger:** Suspected service or security impact following an automatic or manual package update

## 1. Detection Criteria

Open a patch-related incident when one or more of the following occurs after an update:

- A monitored service fails, restarts repeatedly, or becomes unhealthy.
- HTTP, TLS, database, SSH, or other application health checks fail.
- DPKG reports half-configured or half-installed packages, broken dependencies, or interrupted operations.
- A kernel, libc, OpenSSL, certificate, web-server, database, or runtime update correlates with a new error.
- Error rates, latency, authentication failures, or customer reports increase shortly after a patch.
- `apt`, `dpkg`, unattended-upgrades, or reboot logs report an incomplete or failed transaction.

Treat active exploitation, data loss, or a critical customer outage as a Severity 1 incident and page the incident commander immediately.

## 2. Initial Assessment: First Five Minutes

The on-call engineer should preserve evidence and work through this checklist:

1. Record the time, affected service, host, symptoms, recent deployment/change ID, and current operator.
2. Confirm scope: one host, a cluster, a region, or all environments.
3. Check service and customer impact without making package changes:

   ```sh
   systemctl status <service>
   journalctl -u <service> --since "30 minutes ago"
   curl -fsS --max-time 10 http://localhost/
   ```

4. Check recent package activity and system state:

   ```sh
   ./0-diagnose_apt.sh
   tail -200 /var/log/apt/history.log
   tail -200 /var/log/dpkg.log
   ```

5. Do not delete active locks, reboot, purge packages, or run a broad upgrade until the incident commander approves the action. If package operations are active, allow them to finish or stop them through the approved emergency process.

Assign an incident commander, technical lead, and communications owner for Severity 1 or 2 incidents.

## 3. Diagnosis Steps

### Establish the change timeline

Capture the first observed error time and compare it with APT history, DPKG logs, unattended-upgrades logs, system journal entries, and reboot records. Identify packages installed or upgraded in the preceding 24 hours:

```sh
./20-identify_bad_update.sh "YYYY-MM-DD HH:MM"
```

Prioritize packages whose function matches the symptom. For TLS failures, inspect certificate, OpenSSL, libssl, curl, and network-library changes. For web failures, inspect Apache, PHP, modules, and libraries. Confirm the candidate with package versions and policy:

```sh
dpkg-query -W -f='${Package} ${Version}\n' <package>
./12-package_policy.sh <package>
```

### Rule out other causes

- Compare an affected host with a healthy host.
- Check repository changes, configuration drift, expired certificates, DNS, firewall rules, disk space, and time synchronization.
- Confirm the package transaction completed and that no packages remain half-configured.
- Test the application using the same endpoint and credentials that demonstrate the failure.
- Preserve relevant logs, command output, package versions, and configuration checksums in the incident record.

Do not label a package as the cause solely because it was updated. Record the evidence connecting the version change to the symptom.

## 4. Rollback Procedure

Rollback requires incident-commander approval unless a pre-approved emergency runbook applies.

1. Isolate or drain the affected host if continued service could cause data loss. Keep required monitoring and access available.
2. Record the current version and confirm the previous version is available:

   ```sh
   dpkg-query -W -f='${Version}' <package>
   apt-cache madison <package>
   ```

3. Create or confirm a pre-rollback snapshot of DPKG status and APT configuration.
4. Roll back the exact package version:

   ```sh
   ./21-rollback_package.sh <package> <previous-version>
   ```

   The rollback must use `--allow-downgrades`, never an unbounded `apt upgrade`.

5. Reconfigure and verify the package database if required:

   ```sh
   dpkg --configure -a
   apt-get check
   ```

6. Restart only the affected service, then run application, TLS, database, and monitoring health checks.
7. If the rollback succeeds, place a temporary hold only when necessary to prevent immediate re-upgrade:

   ```sh
   ./22-hold_package.sh <package> "<incident ID and reason>"
   ```

   Holds must have an owner and review date. List them regularly with `./23-manage_holds.sh list`.
8. If rollback fails, stop further changes, preserve evidence, apply a vendor workaround or isolation control, and escalate to the platform and security teams.

Never remove package locks blindly. Use `./1-unlock_dpkg.sh` only after confirming that no APT or DPKG process is active.

## 5. Communication Plan

- **Immediately:** Page the incident commander and on-call platform engineer for Severity 1/2 incidents.
- **Within 15 minutes:** Notify the service owner, security team, and change manager with impact, timeline, suspected package, and mitigation status.
- **For customer impact:** Notify the support/customer communications lead using the approved status-page process. Do not disclose unverified root cause.
- **During recovery:** Provide updates at least every 30 minutes for Severity 1 and every hour for Severity 2, or at the cadence set by the incident commander.
- **At restoration:** Announce service recovery only after health checks and monitoring confirm stability.
- **After closure:** Send a written incident summary to the CISO, service owner, and change manager, including corrective actions and owners.

All communications must reference the incident ID and distinguish confirmed facts, hypotheses, and pending tests.

## 6. Post-Incident Review Template

Complete the review within five business days of service restoration.

```text
Incident ID:
Date/time detected:
Date/time resolved:
Severity:
Incident commander:
Service owner:

Summary:

Customer and business impact:

Detection source and first error:

Timeline:
- Update started/completed:
- Error first observed:
- Incident declared:
- Mitigation applied:
- Rollback or fix completed:
- Service verified:

Root cause and contributing factors:

Package(s), previous version(s), and affected version(s):

Evidence collected:

What went well:

What did not go well:

Corrective and preventive actions:
- Action / owner / due date / tracking ID

Hold or blacklist decision:

Communication assessment:

Approval to close:
```

The review must update monitoring, testing, maintenance windows, package policy, or rollback automation when a gap is found. Temporary holds and exceptions remain open until an owner confirms release or a formally approved replacement control.
