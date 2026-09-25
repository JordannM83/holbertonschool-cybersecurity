#!/usr/bin/env python3

import argparse
from collections import Counter, defaultdict, deque
from datetime import datetime
import json
import multiprocessing
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
XSS_SIGNATURES = [
    re.compile(r"<script\b", re.IGNORECASE),
    re.compile(r"javascript\s*:", re.IGNORECASE),
    re.compile(r"on[a-z]+\s*=", re.IGNORECASE),
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
        self.attack_type = fields.get("attack_type", "")


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


def detect_xss(log_entry):
    """Mark an entry as XSS unless SQLi already claimed the attack type."""
    if getattr(log_entry, "attack_type", "") == "SQLi":
        return log_entry

    path = str(getattr(log_entry, "path", ""))
    if any(signature.search(path) for signature in XSS_SIGNATURES):
        log_entry.attack_type = "XSS"
    return log_entry


def detect_bruteforce(entries):
    """Yield brute-force alerts for IPs with more than five failures."""
    failures = Counter()
    for entry in entries:
        message = str(getattr(entry, "message", ""))
        status = str(getattr(entry, "status", ""))
        if (status == "401"
           or "Failed password" in message):
            ip = getattr(entry, "ip", "")
            if ip:
                failures[ip] += 1

    for ip, count in failures.most_common():
        if count > 5:
            yield {
                "ip": ip,
                "count": count,
                "alert_type": "BRUTE_FORCE",
            }


def parse_log_timestamp(timestamp):
    """Parse Apache or Syslog timestamps into a comparable datetime."""
    try:
        return datetime.strptime(timestamp, "%d/%b/%Y:%H:%M:%S %z").replace(
            tzinfo=None
        )
    except ValueError:
        try:
            parsed = datetime.strptime(timestamp, "%b %d %H:%M:%S")
            return parsed.replace(year=datetime.now().year)
        except ValueError:
            return None


def detect_burst(entries, window_seconds=60, threshold=10):
    """Yield one BURST alert when an IP
    reaches threshold in its time window."""
    timestamps = defaultdict(deque)
    alerted = set()

    for entry in entries:
        ip = getattr(entry, "ip", "")
        timestamp = parse_log_timestamp(getattr(entry, "timestamp", ""))
        if not ip or timestamp is None:
            continue

        window = timestamps[ip]
        window.append(timestamp)
        while window and ((timestamp - window[0]).total_seconds()
                          > window_seconds):
            window.popleft()

        if len(window) >= threshold and ip not in alerted:
            alerted.add(ip)
            yield {
                "ip": ip,
                "count": len(window),
                "window": window_seconds,
                "alert_type": "BURST",
            }
        elif len(window) < threshold:
            alerted.discard(ip)


def correlate_events(entries):
    """Yield critical incidents when an IP scans and then attempts SQLi."""
    states = defaultdict(set)
    for entry in entries:
        ip = getattr(entry, "ip", "")
        if not ip:
            continue

        if str(getattr(entry, "status", "")) == "404":
            states[ip].add("scanner")
        if getattr(entry, "attack_type", "") == "SQLi":
            states[ip].add("sqli")

        if {"scanner", "sqli"}.issubset(states[ip]):
            yield {
                "ip": ip,
                "stages": ["scanner", "sqli"],
                "alert_type": "CRITICAL INCIDENT",
            }
            states[ip].clear()


def export_report(alerts, filename, format="json"):
    """Export dictionaries and LogEntry objects as indented JSON."""
    if format.lower() != "json":
        raise ValueError("Only JSON reports are supported")

    serializable = []
    for alert in alerts:
        if isinstance(alert, dict):
            serializable.append(alert)
        elif isinstance(alert, LogEntry):
            serializable.append(vars(alert).copy())
        else:
            raise TypeError("Report entries must be dict or LogEntry objects")

    with open(filename, "w", encoding="utf-8") as report:
        json.dump(serializable, report, indent=2)
        report.write("\n")


def process_chunk(lines):
    """Parse and enrich a chunk of raw lines in one worker process."""
    results = []
    for line in lines:
        apache_entry = parse_apache_line(line)
        if apache_entry:
            entry = normalize_entry(apache_entry, "apache", line.rstrip("\n"))
        else:
            syslog_entry = parse_syslog_line(line)
            if not syslog_entry:
                continue
            entry = normalize_entry(syslog_entry, "syslog", line.rstrip("\n"))

        enrich_ip(entry)
        analyze_user_agent(entry)
        check_threat_intel(entry)
        detect_sqli(entry)
        detect_xss(entry)
        results.append(entry)
    return results


def _read_chunks(file_path, chunk_size):
    """Yield bounded lists of raw lines for
    sequential or parallel processing."""
    chunk = []
    for line in read_stream(file_path):
        chunk.append(line)
        if len(chunk) == chunk_size:
            yield chunk
            chunk = []
    if chunk:
        yield chunk


def parallel_analyze(file_path, num_workers, chunk_size=1000):
    """Process file chunks with a multiprocessing
    pool and merge the results."""
    with multiprocessing.Pool(processes=num_workers) as pool:
        chunk_results = pool.map(
            process_chunk, _read_chunks(file_path, chunk_size)
        )
    return [entry for results in chunk_results for entry in results]


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
    parser.add_argument("--report",
                        help="write alerts to an indented JSON file")
    parser.add_argument("--workers", type=int, default=0,
                        help="number of worker processes (0 uses one process)")
    args = parser.parse_args()

    print("[*] LogHunter - Log Analysis Engine")
    if args.workers > 0:
        print(f"[*] Reading: {args.file} (parallel: {args.workers} workers)")
        parsed_entries = parallel_analyze(args.file, args.workers, 1000)
    else:
        print(f"[*] Reading: {args.file}")
        parsed_entries = [
            entry
            for chunk in _read_chunks(args.file, 1000)
            for entry in process_chunk(chunk)
        ]

    sample_entry = parsed_entries[0] if parsed_entries else None
    apache_lines = 0
    syslog_lines = 0
    suspicious_lines = 0
    enriched_entries = 0
    known_ips = 0
    bots_detected = 0
    high_alerts = 0
    sqli_attempts = 0
    xss_attempts = 0
    brute_force_entries = []
    for entry in parsed_entries:
        if entry.service == "http":
            apache_lines += 1
        elif entry.service == "ssh":
            syslog_lines += 1
        if (str(getattr(entry, "status", "")) == "401"
                or "Failed password" in entry.message):
            brute_force_entries.append(entry)
        enriched_entries += 1
        if entry.country != "UNKNOWN":
            known_ips += 1
        if entry.is_bot:
            bots_detected += 1
        if entry.alert_level == "HIGH":
            high_alerts += 1
        if entry.attack_type == "SQLi":
            sqli_attempts += 1
        if entry.attack_type == "XSS":
            xss_attempts += 1
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
    print(f"[*] XSS attempts:  {xss_attempts}")
    brute_force_alerts = list(detect_bruteforce(brute_force_entries))
    print("--- Brute Force ---")
    print(f"[*] BRUTE_FORCE alerts: {len(brute_force_alerts)}")
    for alert in brute_force_alerts:
        print(f"    {alert['ip']}: {alert['count']} failures")
    burst_alerts = list(detect_burst(parsed_entries))
    print("--- Burst Detection ---")
    print(f"[*] BURST alerts: {len(burst_alerts)}")
    for alert in burst_alerts:
        print(
            f"    {alert['ip']}: {alert['count']} requests in "
            f"{alert['window']}s window"
        )
    incidents = list(correlate_events(parsed_entries))
    print("--- Correlation ---")
    print("[*] CRITICAL INCIDENTS:")
    for incident in incidents:
        print(f"    {incident['ip']}: scanner -> sqli")

    alerts = brute_force_alerts + burst_alerts + incidents
    if args.report:
        export_report(alerts, args.report)
        print(f"[*] Report exported: {args.report} ({len(alerts)} alerts)")
    else:
        print(f"[*] Total alerts: {len(alerts)}")
        print("[*] Use --report <file> to export.")


if __name__ == "__main__":
    main()
