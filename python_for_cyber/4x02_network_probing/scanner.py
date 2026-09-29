"""Socket and scanning logic."""

import socket
from pathlib import Path
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

MODULE_DIR = str(Path(__file__).resolve().parent)
if MODULE_DIR not in sys.path:
    sys.path.insert(0, MODULE_DIR)

from utils import (check_vulnerability, shuffle_ports, sleep_before_scan)

SCAN_DELAY = 0.0
RANDOM_SCAN = False
SOURCE_IP = None


def configure(delay: float = 0.0, randomize: bool = False,
              source_ip: str = None) -> None:
    """Set defaults used by scans started without explicit options."""
    global SCAN_DELAY, RANDOM_SCAN, SOURCE_IP
    SCAN_DELAY = delay
    RANDOM_SCAN = randomize
    SOURCE_IP = source_ip


def check_port(ip: str, port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(1)
        try:
            if SOURCE_IP:
                sock.bind((SOURCE_IP, 0))
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
            if SOURCE_IP:
                sock.bind((SOURCE_IP, 0))
            sock.connect((ip, port))

            if port == 80:
                request = (f"GET / HTTP/1.1\r\nHost: {ip}\r\n\r\n").encode()
            else:
                request = b"HEAD / HTTP/1.0\r\n\r\n"
            sock.sendall(request)

            banner = sock.recv(1024)
            if not banner:
                return "Unknown"

            response = banner.decode(errors="ignore").strip()
            if port == 80:
                for line in response.splitlines():
                    if line.lower().startswith("server:"):
                        return f"HTTP ({line.split(':', 1)[1].strip()})"
                return "Unknown"
            return response
    except OSError:
        return "Unknown"


def scan_udp(ip: str, port: int) -> bool:
    """Probe UDP, treating a timeout as open or filtered."""
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.settimeout(2)
        try:
            if SOURCE_IP:
                sock.bind((SOURCE_IP, 0))
            sock.sendto(b"", (ip, port))
            sock.recvfrom(1024)
            return True
        except socket.timeout:
            return True
        except OSError:
            return False


def resolve_hostname(ip: str) -> str:
    try:
        hostname, _, _ = socket.gethostbyaddr(ip)
        return hostname
    except OSError:
        return "Unknown"


def scan_ports(ip: str, start_port: int, end_port: int,
               delay: float = None, randomize: bool = None) -> list:
    results = []
    delay = SCAN_DELAY if delay is None else delay
    randomize = RANDOM_SCAN if randomize is None else randomize
    ports = list(range(start_port, end_port + 1))

    if randomize:
        shuffle_ports(ports)
        print("Scanning ports randomly...")
    else:
        print(f"Scanning {ip} from {start_port} to {end_port}...")

    def scan_port(port):
        sleep_before_scan(delay)
        if check_port(ip, port):
            service = get_banner(ip, port)
            return {
                "port": port,
                "state": "open",
                "service": service,
                "vulnerability": "YES" if check_vulnerability(service)
                else "NO",
            }
        return None

    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = [executor.submit(scan_port, port) for port in ports]
        for future in as_completed(futures):
            result = future.result()
            if result is not None:
                results.append(result)
                vulnerability = check_vulnerability(result["service"])
                port_label = (f"Port {result['port']}:"
                              if result["port"] == 80
                              else f"Port {result['port']} Open:")
                print(f"[+] {port_label} {result['service']}"
                      f"{' ' + vulnerability if vulnerability else ''}")

    results.sort(key=lambda item: item["port"])
    return results
