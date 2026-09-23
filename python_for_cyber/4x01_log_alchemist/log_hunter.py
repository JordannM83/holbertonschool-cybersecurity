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


class LogEntry:
    """Common representation for Apache and Syslog records."""

    def __init__(self, ip, timestamp, service, message, raw_line="", **fields):
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
                entry = normalize_entry(syslog_entry, "syslog", line.rstrip("\n"))
            else:
                continue

        if sample_entry is None:
            sample_entry = entry
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


if __name__ == "__main__":
    main()
