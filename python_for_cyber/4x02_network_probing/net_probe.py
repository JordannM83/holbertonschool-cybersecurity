#!/usr/bin/env python3
import socket


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
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(2)

        try:
            sock.connect((ip, port))

            if port == 80:
                sock.sendall(b"HEAD / HTTP/1.0\r\n\r\n")

            banner = sock.recv(1024)
            return banner.decode(errors="ignore").strip()

        except OSError:
            return "Unknown"


def main():
    """main function"""
    print(f"Port 80 is open: {check_port('google.com', 80)}")
    print(f"Port 81 is open: {check_port('google.com', 81)}")
    print(ping_sweep("192.168.1"))
    print(get_banner("scanme.nmap.org", 22))
    return
