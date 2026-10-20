# Bastion Host Hardening Report

**System:** NovaTech production web server  
**Assessment:** Lynis baseline and post-hardening review  
**Status:** Pending CISO approval for DMZ deployment

## 1. Executive Summary

The bastion host was hardened against common network, local privilege-escalation, filesystem, service, and account attacks. The work reduced unnecessary attack surface while preserving required administrative and web-service functions.

The recorded Lynis hardening index improved from **62** before hardening to **84** after hardening. Warnings decreased from **18** to **4**, and suggestions decreased from **45** to **12**. Final approval remains subject to review of the residual findings and completion of the sign-off checklist below.

## 2. Baseline Assessment

The baseline was captured with `0-lynis_baseline.sh` and stored in `/var/log/hardening/baseline-YYYYMMDD.txt`.

| Measure | Before hardening |
|---|---:|
| Lynis hardening index | 62 |
| Tests performed | 256 |
| Warnings | 18 |
| Suggestions | 45 |
| Key findings | IP forwarding, SUID custom binary, permissive temporary filesystems, unnecessary tools/services |

## 3. Hardening Measures Applied

### Kernel and network

- Disabled IPv4 and IPv6 forwarding.
- Disabled acceptance and sending of ICMP redirects.
- Enabled strict IPv4 reverse-path filtering.
- Enabled TCP SYN cookies.
- Disabled source-routed packet acceptance.
- Disabled broadcast ping responses while retaining unicast ping for diagnostics.
- Persisted kernel settings in `/etc/sysctl.d/99-hardening.conf`.

### Software

- Audited development, network-debugging, and remote-access packages.
- Removed compilers where safe and restricted retained tools to root when removal was unsuitable.
- Restricted `nc`, `ncat`, `nmap`, and `tcpdump` to root-only execution.

### Privileges and accounts

- Audited SUID/SGID binaries and removed SUID from non-essential binaries, including custom backup tooling.
- Locked the root account after confirming sudo access and configuration validity.
- Restricted administrative utilities and network tools to root-only execution where retention was required.

### Services

- Disabled and stopped unnecessary services such as CUPS, Avahi, and Bluetooth.
- Preserved required SSH and web-server services.
- Validated SSH configuration before reload and documented the legal access banner.

### Filesystem

- Applied `noexec`, `nosuid`, and `nodev` protections to `/tmp`, `/var/tmp`, and `/dev/shm`.
- Persisted mount settings through `/etc/fstab`.
- Tested execution blocking and verified active mount options.

## 4. Final Assessment

The final assessment is produced by `23-final_audit.sh`, which runs Lynis, stores the report under `/var/log/hardening/final-YYYYMMDD.txt`, and compares it with the latest baseline.

| Measure | Baseline | Final | Change |
|---|---:|---:|---:|
| Lynis hardening index | 62 | 84 | +22 |
| Warnings | 18 | 4 | -14 |
| Suggestions | 45 | 12 | -33 |

The resulting improvement is significant. The final Lynis report and kernel verification output must be attached to the change record before deployment approval.

## 5. Remaining Recommendations

The following residual items require review or follow-up:

- Evaluate deployment of `auditd` for privileged-action and security-event auditing.
- Deploy host-based intrusion detection or an equivalent monitored control.
- Confirm log rotation and retention for system, SSH, service, and hardening logs.
- Enable process accounting if required by the organization’s audit standard.
- Review all remaining Lynis warnings and suggestions against the DMZ baseline.
- Re-run Lynis after OS, kernel, web-server, or authentication changes.
- Keep SUID/SGID inventories and package audits in the change-management record.

## 6. Sign-off Checklist

- [ ] Baseline Lynis report archived.
- [ ] Final Lynis report archived and compared with the baseline.
- [ ] `8-verify_kernel.sh` reports all checks passed.
- [ ] Temporary filesystem restrictions verified after reboot.
- [ ] Required services tested from an approved monitoring point.
- [ ] SSH sudo access and legal banner verified.
- [ ] Root account lockout approved and recovery access documented.
- [ ] Residual Lynis warnings assigned to owners with due dates.
- [ ] Firewall, logging, backup, and monitoring controls reviewed by the CISO.
- [ ] DMZ deployment approved by the service owner and change authority.

**Security engineering sign-off:** ____________________  **Date:** __________

**Service owner sign-off:** ___________________________  **Date:** __________

**CISO approval:** ____________________________________  **Date:** __________

