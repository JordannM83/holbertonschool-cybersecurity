# Hardened Shield Security Audit

Generated: 2026-10-28T10:55:11.608454+00:00

Overall result: **FAIL**
Overall score: **42%** (10/24 checks passed)

| Category | Score | Status |
|---|---:|---|
| Kernel hardening | 56% | FAIL |
| Filesystem security | 0% | FAIL |
| Identity security | 0% | FAIL |
| Service security | 0% | FAIL |
| Container security | 100% | PASS |

## Detailed Results

### Kernel hardening

| Check | Result | Details |
|---|---|---|
| net.ipv4.ip_forward | FAIL | expected 0, found 1 |
| net.ipv6.conf.all.forwarding | PASS | expected 0, found 0 |
| net.ipv4.conf.all.accept_redirects | PASS | expected 0, found 0 |
| net.ipv4.conf.default.accept_redirects | FAIL | expected 0, found 1 |
| net.ipv4.conf.all.send_redirects | FAIL | expected 0, found 1 |
| net.ipv4.conf.all.rp_filter | FAIL | expected 1, found 0 |
| net.ipv4.tcp_syncookies | PASS | expected 1, found 1 |
| net.ipv4.icmp_echo_ignore_broadcasts | PASS | expected 1, found 1 |
| net.ipv4.conf.all.accept_source_route | PASS | expected 0, found 0 |

### Filesystem security

| Check | Result | Details |
|---|---|---|
| /tmp restrictions | FAIL | missing noexec |
| /var/tmp restrictions | FAIL | missing nodev, noexec, nosuid |
| /dev/shm restrictions | FAIL | missing noexec |

### Identity security

| Check | Result | Details |
|---|---|---|
| Password complexity | FAIL | pwquality and PAM module configured |
| Password history | FAIL | last five passwords remembered |
| Account lockout | FAIL | faillock threshold and PAM stack configured |
| SSH authentication hardening | FAIL | password login disabled and root login prohibited |

### Service security

| Check | Result | Details |
|---|---|---|
| Web server process | FAIL | not running |
| SSH server process | FAIL | not running |
| HTTP health endpoint | FAIL | HTTP endpoint responded |

### Container security

| Check | Result | Details |
|---|---|---|
| Non-root execution | PASS | effective UID 1000 |
| Capabilities dropped | PASS | CapEff 0000000000000000 |
| No new privileges | PASS | NoNewPrivs 1 |
| Seccomp filtering | PASS | Seccomp 2 |
| Read-only root filesystem | PASS | root mount is read-only |

## Interpretation

A PASS requires at least 80% overall. Any failed control should be reviewed
before production deployment; critical identity or container failures should
block release until remediated.
