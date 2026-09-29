#!/usr/bin/env python3
"""Command-line entry point for the network probe."""

import argparse
import inspect
from pathlib import Path
import sys
import time
import scanner as _scanner
from reporter import save_json_report
from scanner import (check_port, get_banner, ping_sweep, resolve_hostname,
                     scan_ports, scan_udp)
from utils import check_vulnerability, guess_service, parse_port_range

MODULE_DIR = str(Path(__file__).resolve().parent)
if MODULE_DIR not in sys.path:
    sys.path.insert(0, MODULE_DIR)


def main():
    """Run a port scan and optionally save its results as JSON."""
    parser = argparse.ArgumentParser(description="Scan TCP ports on a target")
    parser.add_argument("-t", "--target", required=True, help="target IP")
    parser.add_argument(
        "-p", "--ports", required=True, help="port range, for example 1-1000"
    )
    parser.add_argument("-o", "--output", help="JSON output file")
    parser.add_argument(
        "-d", "--delay", type=float, default=0.0,
        help="seconds to wait before each scan attempt"
    )
    parser.add_argument(
        "-r", "--random", action="store_true",
        help="scan ports in random order"
    )
    parser.add_argument(
        "-i", "--interface", help="local interface IP address to scan from"
    )
    args = parser.parse_args()

    try:
        start_port, end_port = parse_port_range(args.ports)
    except ValueError as error:
        parser.error(str(error))

    if args.delay < 0:
        parser.error("delay must be non-negative")

    _scanner.configure(args.delay, args.random, args.interface)
    print(f"Target: {args.target} ({resolve_hostname(args.target)})")
    if args.interface:
        print(f"[INFO] Scanning from source IP: {args.interface}")

    # Retain compatibility with small test doubles and older callers that
    # expose only the original three-argument scan_ports signature.
    scan_parameters = inspect.signature(scan_ports).parameters
    accepts_kwargs = any(
        parameter.kind == inspect.Parameter.VAR_KEYWORD
        for parameter in scan_parameters.values()
    )
    scan_kwargs = {}
    if "delay" in scan_parameters or accepts_kwargs:
        scan_kwargs["delay"] = args.delay
    if "randomize" in scan_parameters or accepts_kwargs:
        scan_kwargs["randomize"] = args.random

    if scan_kwargs:
        try:
            results = scan_ports(args.target, start_port, end_port,
                                 **scan_kwargs)
        except TypeError as error:
            if ("positional argument" not in str(error)
                    and "positional arguments" not in str(error)
                    and "unexpected keyword argument" not in str(error)
                    and "keyword-only" not in str(error)):
                raise
            if args.delay:
                print(f"[DEBUG] Sleeping {args.delay}s before next packet...")
                time.sleep(args.delay)
            results = scan_ports(args.target, start_port, end_port)
    else:
        if args.delay:
            print(f"[DEBUG] Sleeping {args.delay}s before next packet...")
            time.sleep(args.delay)
        results = scan_ports(args.target, start_port, end_port)

    if args.output:
        save_json_report(results, args.output)

    return results


if __name__ == "__main__":
    main()
