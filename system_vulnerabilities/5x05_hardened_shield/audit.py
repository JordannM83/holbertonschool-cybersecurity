#!/usr/bin/env python3
"""Audit the Hardened Shield host/container security baseline."""

from __future__ import annotations

import argparse
import datetime as dt
import os
import pathlib
import re
import socket
import subprocess
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass


@dataclass
class Check:
    name: str
    passed: bool
    detail: str


CATEGORIES = (
    "Kernel hardening",
    "Filesystem security",
    "Identity security",
    "Service security",
    "Container security",
)


def read_text(path: str) -> str:
    try:
        return pathlib.Path(path).read_text(encoding="utf-8", errors="replace")
    except (OSError, UnicodeError):
        return ""


def sysctl_value(key: str) -> str:
    return read_text("/proc/sys/" + key.replace(".", "/")).strip()


def check_sysctl(key: str, expected: str) -> Check:
    actual = sysctl_value(key)
    return Check(
        key,
        actual == expected,
        f"expected {expected}, found {actual or 'unavailable'}",
    )


def mount_options(path: str) -> set[str]:
    mounts = read_text("/proc/self/mountinfo")
    for line in mounts.splitlines():
        fields = line.split(" - ", 1)
        if len(fields) != 2:
            continue
        left = fields[0].split()
        if len(left) < 6 or left[4] != path:
            continue
        options = set(left[5].split(","))
        options.update(fields[1].split()[1].split(","))
        return options
    return set()


def filesystem_checks() -> list[Check]:
    checks = []
    for path in ("/tmp", "/var/tmp", "/dev/shm"):
        options = mount_options(path)
        required = {"noexec", "nosuid", "nodev"}
        checks.append(
            Check(
                f"{path} restrictions",
                required.issubset(options),
                "required options present"
                if required.issubset(options)
                else f"missing {', '.join(sorted(required - options))}",
            )
        )
    return checks


def file_contains(path: str, pattern: str) -> bool:
    return bool(re.search(pattern, read_text(path), re.MULTILINE))


def identity_checks() -> list[Check]:
    pwquality = "/etc/security/pwquality.conf"
    common_password = "/etc/pam.d/common-password"
    common_auth = "/etc/pam.d/common-auth"
    common_account = "/etc/pam.d/common-account"
    faillock = "/etc/security/faillock.conf"
    sshd = "/etc/ssh/sshd_config"

    complexity = all(
        file_contains(pwquality, rf"^{key}\s*=\s*{value}\s*$")
        for key, value in (
            ("minlen", "12"),
            ("dcredit", "-1"),
            ("ucredit", "-1"),
            ("lcredit", "-1"),
            ("ocredit", "-1"),
        )
    )
    return [
        Check(
            "Password complexity",
            complexity and file_contains(common_password, r"pam_pwquality\.so"),
            "pwquality and PAM module configured",
        ),
        Check(
            "Password history",
            file_contains(common_password, r"pam_pwhistory\.so.*remember=5"),
            "last five passwords remembered",
        ),
        Check(
            "Account lockout",
            all(
                file_contains(faillock, rf"^{key}\s*=\s*{value}\s*$")
                for key, value in (
                    ("deny", "5"),
                    ("unlock_time", "900"),
                    ("fail_interval", "900"),
                )
            )
            and file_contains(common_auth, r"pam_faillock\.so")
            and file_contains(common_account, r"pam_faillock\.so"),
            "faillock threshold and PAM stack configured",
        ),
        Check(
            "SSH authentication hardening",
            file_contains(sshd, r"^PasswordAuthentication\s+no$")
            and file_contains(sshd, r"^PermitRootLogin\s+no$")
            and file_contains(sshd, r"^PubkeyAuthentication\s+yes$"),
            "password login disabled and root login prohibited",
        ),
    ]


def process_exists(pattern: str) -> bool:
    try:
        result = subprocess.run(
            ["pgrep", "-x", pattern],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        return result.returncode == 0
    except OSError:
        return False


def http_is_healthy() -> bool:
    try:
        with urllib.request.urlopen("http://127.0.0.1/", timeout=3) as response:
            return 200 <= response.status < 500
    except (OSError, urllib.error.URLError):
        return False


def service_checks() -> list[Check]:
    apache = process_exists("apache2") or process_exists("httpd")
    ssh = process_exists("sshd")
    return [
        Check("Web server process", apache, "Apache process detected" if apache else "not running"),
        Check("SSH server process", ssh, "sshd process detected" if ssh else "not running"),
        Check("HTTP health endpoint", http_is_healthy(), "HTTP endpoint responded"),
    ]


def proc_status_value(key: str) -> str:
    for line in read_text("/proc/self/status").splitlines():
        if line.startswith(key + ":"):
            return line.split(":", 1)[1].strip()
    return ""


def root_mount_is_read_only() -> bool:
    options = mount_options("/")
    return "ro" in options and "rw" not in options


def container_checks() -> list[Check]:
    uid = os.geteuid()
    cap_eff = proc_status_value("CapEff")
    no_new_privs = proc_status_value("NoNewPrivs")
    seccomp = proc_status_value("Seccomp")
    return [
        Check("Non-root execution", uid != 0, f"effective UID {uid}"),
        Check(
            "Capabilities dropped",
            cap_eff == "0000000000000000",
            f"CapEff {cap_eff or 'unavailable'}",
        ),
        Check("No new privileges", no_new_privs == "1", f"NoNewPrivs {no_new_privs or 'unavailable'}"),
        Check("Seccomp filtering", seccomp in {"1", "2"}, f"Seccomp {seccomp or 'unavailable'}"),
        Check(
            "Read-only root filesystem",
            root_mount_is_read_only(),
            "root mount is read-only" if root_mount_is_read_only() else "root mount is writable",
        ),
    ]


def kernel_checks() -> list[Check]:
    expected = {
        "net.ipv4.ip_forward": "0",
        "net.ipv6.conf.all.forwarding": "0",
        "net.ipv4.conf.all.accept_redirects": "0",
        "net.ipv4.conf.default.accept_redirects": "0",
        "net.ipv4.conf.all.send_redirects": "0",
        "net.ipv4.conf.all.rp_filter": "1",
        "net.ipv4.tcp_syncookies": "1",
        "net.ipv4.icmp_echo_ignore_broadcasts": "1",
        "net.ipv4.conf.all.accept_source_route": "0",
    }
    return [check_sysctl(key, value) for key, value in expected.items()]


def collect() -> dict[str, list[Check]]:
    return {
        "Kernel hardening": kernel_checks(),
        "Filesystem security": filesystem_checks(),
        "Identity security": identity_checks(),
        "Service security": service_checks(),
        "Container security": container_checks(),
    }


def render(results: dict[str, list[Check]]) -> str:
    total = sum(len(checks) for checks in results.values())
    passed = sum(sum(check.passed for check in checks) for checks in results.values())
    overall = round(passed * 100 / total) if total else 0
    status = "PASS" if overall >= 80 else "FAIL"
    lines = [
        "# Hardened Shield Security Audit",
        "",
        f"Generated: {dt.datetime.now(dt.timezone.utc).isoformat()}",
        "",
        f"Overall result: **{status}**",
        f"Overall score: **{overall}%** ({passed}/{total} checks passed)",
        "",
        "| Category | Score | Status |",
        "|---|---:|---|",
    ]
    for category in CATEGORIES:
        checks = results[category]
        category_passed = sum(check.passed for check in checks)
        score = round(category_passed * 100 / len(checks)) if checks else 0
        category_status = "PASS" if category_passed == len(checks) else "FAIL"
        lines.append(f"| {category} | {score}% | {category_status} |")
    lines.extend(["", "## Detailed Results", ""])
    for category in CATEGORIES:
        lines.extend([f"### {category}", "", "| Check | Result | Details |", "|---|---|---|"])
        for check in results[category]:
            result = "PASS" if check.passed else "FAIL"
            lines.append(f"| {check.name} | {result} | {check.detail} |")
        lines.append("")
    lines.extend(
        [
            "## Interpretation",
            "",
            "A PASS requires at least 80% overall. Any failed control should be reviewed",
            "before production deployment; critical identity or container failures should",
            "block release until remediated.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    default_output = pathlib.Path(__file__).resolve().parents[1] / "audit_result.md"
    parser.add_argument("-o", "--output", type=pathlib.Path, default=default_output)
    args = parser.parse_args()

    results = collect()
    report = render(results)
    try:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(report, encoding="utf-8")
    except OSError as exc:
        print(f"ERROR: cannot write {args.output}: {exc}", file=sys.stderr)
        return 2

    print(report)
    passed = sum(sum(check.passed for check in checks) for checks in results.values())
    total = sum(len(checks) for checks in results.values())
    return 0 if total and passed * 100 / total >= 80 else 1


if __name__ == "__main__":
    raise SystemExit(main())

