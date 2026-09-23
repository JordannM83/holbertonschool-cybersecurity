#!/usr/bin/env python3

import argparse
import re


APACHE_PATTERN = re.compile(
    r'(?P<ip>\S+)\s+-\s+-\s+'
    r'\[(?P<date>[^]]+)\]\s+'
    r'"(?P<method>\S+)\s+(?P<path>\S+)\s+HTTP/[^"]+"\s+'
    r'(?P<status>\d{3})\s+(?P<size>\d+|-)'
)


def parse_apache_line(line: str) -> dict:
    """Parse one Apache access-log line, or return None if it does not match."""
    match = re.search(APACHE_PATTERN, line)
    return match.groupdict() if match else None


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
    for line in read_stream(args.file):
        if parse_apache_line(line):
            apache_lines += 1

    total_parsed = apache_lines + syslog_lines
    if total_parsed == 0:
        print("[!] No data to process. Exiting.")
        return

    print("--- Parsing ---")
    print(f"[*] Apache lines:  {apache_lines}")
    print(f"[*] Syslog lines:  {syslog_lines}")
    print(f"[*] Total parsed:  {total_parsed}")


if __name__ == "__main__":
    main()
