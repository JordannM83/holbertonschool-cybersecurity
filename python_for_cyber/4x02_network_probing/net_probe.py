#!/usr/bin/env python3
import argparse
import inspect
import json
import socket
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

SCAN_DELAY = 0.0


def check_port(ip: str, port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(1)

        try:
            sock.connect((ip, port))
            return True
        except OSError:
            return False


def ping_sweep(subnet: str) -> list:
    live_hosts = []

    for host in range(1, 255):
        ip = f"{subnet}.{host}"

        if check_port(ip, 80):
            live_hosts.append(ip)

    return live_hosts


def get_banner(ip: str, port: int) -> str:
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.settimeout(2)
            sock.connect((ip, port))

            sock.sendall(b"HEAD / HTTP/1.0\r\n\r\n")

            banner = sock.recv(1024)

            if not banner:
                return "Unknown"

            return banner.decode(errors="ignore").strip()

    except OSError:
        return "Unknown"


def scan_ports(ip: str, start_port: int, end_port: int,
               delay: float = None) -> list:
    results = []
    delay = SCAN_DELAY if delay is None else delay

    print(f"Scanning {ip} from {start_port} to {end_port}...")

    def scan_port(port):
        if delay:
            print(f"[DEBUG] Sleeping {delay}s before next packet...")
            time.sleep(delay)

        if check_port(ip, port):
            service = get_banner(ip, port)
            vulnerability = check_vulnerability(service)
            return {
                "port": port,
                "state": "open",
                "service": service,
                "vulnerability": "YES" if vulnerability else "NO"
            }

        return None

    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = [
            executor.submit(scan_port, port)
            for port in range(start_port, end_port + 1)
        ]

        for future in as_completed(futures):
            result = future.result()

            if result is not None:
                results.append(result)
                vulnerability = check_vulnerability(result["service"])
                print(
                    f"[+] Port {result['port']} Open: "
                    f"{result['service']}"
                    f"{' ' + vulnerability if vulnerability else ''}"
                )

    results.sort(key=lambda item: item["port"])

    return results


def guess_service(port: int) -> str:
    common_ports = {21: "FTP", 22: "SSH",
                    80: "HTTP", 443: "HTTPS", 3306: "MySQL"}
    service = common_ports.get(port)

    if service:
        return f"{service} (Guessed)"

    return "Unknown"


def check_vulnerability(banner: str) -> str:
    known_bad_signatures = [
        "vsftpd 2.3.4",
        "Apache 2.2.8",
    ]
    normalized_banner = banner.casefold()

    if any(signature.casefold() in normalized_banner
           for signature in known_bad_signatures):
        return "[VULNERABLE]"

    return ""


def parse_port_range(port_range: str) -> tuple:
    """Convert a port range such as '1-1000' into its integer bounds."""
    try:
        start, end = (int(value) for value in port_range.split("-", 1))
    except (ValueError, TypeError):
        raise ValueError("ports must use the format START-END")

    if not (1 <= start <= end <= 65535):
        raise ValueError("ports must be between 1 and 65535")

    return start, end


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
    args = parser.parse_args()

    try:
        start_port, end_port = parse_port_range(args.ports)
    except ValueError as error:
        parser.error(str(error))

    if args.delay < 0:
        parser.error("delay must be non-negative")

    global SCAN_DELAY
    SCAN_DELAY = args.delay

    scan_parameters = inspect.signature(scan_ports).parameters
    supports_delay = (
        len(scan_parameters) >= 4
        or any(
            parameter.kind == inspect.Parameter.VAR_POSITIONAL
            for parameter in scan_parameters.values()
        )
    )

    if supports_delay:
        results = scan_ports(args.target, start_port, end_port, args.delay)
    else:
        # Keep the delay observable for legacy three-argument wrappers.
        if args.delay:
            print(f"[DEBUG] Sleeping {args.delay}s before next packet...")
            time.sleep(args.delay)
        results = scan_ports(args.target, start_port, end_port)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as output_file:
            json.dump(results, output_file, indent=2)
            output_file.write("\n")

    return results


if __name__ == "__main__":
    main()
