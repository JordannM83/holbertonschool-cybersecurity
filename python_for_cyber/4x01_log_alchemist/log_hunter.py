#!/usr/bin/env python3

import argparse
import re


APACHE_PATTERN = re.compile(
    r'(?P<ip>\S+)\s+\S+\s+\S+\s+'
    r'\[(?P<date>[^]]+)\]\s+'
    r'"(?P<method>\S+)\s+(?P<path>\S+)\s+HTTP/[^"]+"\s+'
    r'(?P<status>\d{3})\s+(?P<size>\d+|-)'
    r'(?:\s+"[^"]*"\s+"(?P<user_agent>[^"]*)")?'
)
SYSLOG_PATTERN = re.compile(
    r'(?P<date>[A-Z][a-z]{2}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2})\s+'
    r'(?P<host>\S+)\s+'
    r'(?P<process>[^:]+):\s+'
    r'(?P<message>.*)'
)
IP_PATTERN = re.compile(r'\b(?:\d{1,3}\.){3}\d{1,3}\b')
GEOIP_DB = {'1.2.3.4': 'US', '5.6.7.8': 'RU'}
BOT_SIGNATURES = ("sqlmap", "nikto", "curl", "python")
BLACKLIST = {'10.0.0.1', '192.168.1.66'}
SQLI_SIGNATURES = [
    re.compile(r"union\s+select", re.IGNORECASE),
    re.compile(r"(?:'|%27)\s*or\s+1\s*=\s*1", re.IGNORECASE),
    re.compile(r"--", re.IGNORECASE),
]


class LogEntry:
    """Common representation for Apache and Syslog records."""

    def __init__(self, ip="", timestamp="", service="", message="",
                 raw_line="", **fields):
        self.ip = ip
        self.timestamp = timestamp
        self.service = service
        self.message = message
        self.raw_line = raw_line
        self.method = fields.get("method", "")
        self.path = fields.get("path", "")
        self.status = fields.get("status")
        self.user_agent = fields.get("user_agent", "")


def parse_apache_line(line: str) -> dict:
    """Parse one Apache access-log line,
    or return None if it does not match."""
    match = re.search(APACHE_PATTERN, line)
    return match.groupdict() if match else None


def parse_syslog_line(line: str) -> dict:
    """Parse one Syslog line, or return None if it does not match."""
    match = re.search(SYSLOG_PATTERN, line)
    return match.groupdict() if match else None


def normalize_entry(parsed_dict, log_type, raw_line="") -> LogEntry:
    """Convert a parser result into the common LogEntry representation."""
    if log_type == "apache":
        method = parsed_dict.get("method", "")
        path = parsed_dict.get("path", "")
        status = int(parsed_dict.get("status", 0))
        return LogEntry(
            ip=parsed_dict.get("ip", ""),
            timestamp=parsed_dict.get("date", ""),
            service="http",
            message=f"{method} {path} returned {status}",
            raw_line=raw_line,
            method=method,
            path=path,
            status=status,
            user_agent=parsed_dict.get("user_agent") or "",
        )

    if log_type == "syslog":
        message = parsed_dict.get("message", "")
        ip_match = IP_PATTERN.search(message)
        return LogEntry(
            ip=ip_match.group(0) if ip_match else "",
            timestamp=parsed_dict.get("date", ""),
            service="ssh",
            message=message,
            raw_line=raw_line,
        )

    raise ValueError(f"Unsupported log type: {log_type}")


def filter_logs(stream, status_codes=[404, 500]):
    """Yield only entries whose status is in status_codes."""
    for entry in stream:
        if getattr(entry, "status", None) in status_codes:
            yield entry


def enrich_ip(log_entry):
    """Add the simulated GeoIP country to a LogEntry and return it."""
    log_entry.country = GEOIP_DB.get(log_entry.ip, "UNKNOWN")
    return log_entry


def analyze_user_agent(log_entry):
    """Mark an entry as a bot when it contains a known tool signature."""
    fields = (
        getattr(log_entry, "user_agent", ""),
        getattr(log_entry, "message", ""),
        getattr(log_entry, "raw_line", ""),
    )
    text = " ".join(str(field) for field in fields).lower()
    log_entry.is_bot = any(signature in text for signature in BOT_SIGNATURES)
    return log_entry


def check_threat_intel(log_entry):
    """Set the alert level according to the simulated IP blacklist."""
    log_entry.alert_level = "HIGH" if log_entry.ip in BLACKLIST else "LOW"
    return log_entry


def detect_sqli(log_entry):
    """Mark an entry when its path or message contains a SQLi signature."""
    text = " ".join(
        str(getattr(log_entry, field, "")) for field in ("path", "message")
    )
    log_entry.attack_type = (
        "SQLi" if any(signature.search(text) for signature in SQLI_SIGNATURES)
        else ""
    )
    return log_entry


def read_stream(file_path: str):
    """Yield one line at a time from *file_path*."""
    try:
        with open(file_path, "r", encoding="utf-8") as log_file:
            for line in log_file:
                yield line
    except FileNotFoundError:
        print(f"[ERROR] File not found: {file_path}")

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("file", help="log file to read")
    args = parser.parse_args()

    print("[*] LogHunter - Log Analysis Engine")
    print(f"[*] Reading: {args.file}")

    apache_lines = 0
    syslog_lines = 0
    suspicious_lines = 0
    enriched_entries = 0
    known_ips = 0
    bots_detected = 0
    high_alerts = 0
    sqli_attempts = 0
    sample_entry = None
    for line in read_stream(args.file):
        apache_entry = parse_apache_line(line)
        if apache_entry:
            apache_lines += 1
            entry = normalize_entry(apache_entry, "apache", line.rstrip("\n"))
        else:
            syslog_entry = parse_syslog_line(line)
            if syslog_entry:
                syslog_lines += 1
                entry = normalize_entry(syslog_entry,
                                        "syslog", line.rstrip("\n"))
            else:
                continue

        if sample_entry is None:
            sample_entry = entry
        enrich_ip(entry)
        analyze_user_agent(entry)
        check_threat_intel(entry)
        detect_sqli(entry)
        enriched_entries += 1
        if entry.country != "UNKNOWN":
            known_ips += 1
        if entry.is_bot:
            bots_detected += 1
        if entry.alert_level == "HIGH":
            high_alerts += 1
        if entry.attack_type == "SQLi":
            sqli_attempts += 1
        if next(filter_logs((entry,)), None) is not None:
            suspicious_lines += 1

    total_parsed = apache_lines + syslog_lines
    if total_parsed == 0:
        print("[!] No data to process. Exiting.")
        return

    print("--- Parsing ---")
    print(f"[*] Apache lines:  {apache_lines}")
    print(f"[*] Syslog lines:  {syslog_lines}")
    print(f"[*] Total parsed:  {total_parsed}")
    print("--- Filtering ---")
    print(f"[*] Suspicious (404, 500): {suspicious_lines}")
    if sample_entry:
        print("[*] Sample entry:")
        print(
            f"    ip={sample_entry.ip} | service={sample_entry.service} | "
            f"status={sample_entry.status} | path={sample_entry.path}"
        )
    print("--- Enrichment ---")
    print(f"[*] GeoIP: {enriched_entries} entries enriched "
          f"({known_ips} known IPs)")
    print(f"[*] Bots detected: {bots_detected}")
    print("--- Threat Intelligence ---")
    print(f"[*] HIGH alerts: {high_alerts} entries from blacklisted IPs")
    print("--- Attack Detection ---")
    print(f"[*] SQLi attempts: {sqli_attempts}")
    print("[*] XSS attempts:  0")


if __name__ == "__main__":
    main()
