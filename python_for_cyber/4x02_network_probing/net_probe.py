#!/usr/bin/env python3
import socket
from concurrent.futures import ThreadPoolExecutor, as_completed


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


def scan_ports(ip: str, start_port: int, end_port: int) -> list:
    results = []

    print(f"Scanning {ip} from {start_port} to {end_port}...")

    def scan_port(port):
        if check_port(ip, port):
            service = get_banner(ip, port)
            return {
                "port": port,
                "service": service
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
                print(
                    f"[+] Port {result['port']} Open: "
                    f"{result['service']}"
                )

    results.sort(key=lambda item: item["port"])

    return results


def main():
    """main function"""
    print(f"Port 80 is open: {check_port('google.com', 80)}")
    print(f"Port 81 is open: {check_port('google.com', 81)}")
    print(ping_sweep("192.168.1"))
    print(get_banner("scanme.nmap.org", 22))
    scan_ports("192.168.1.1", 20, 80)
    return
