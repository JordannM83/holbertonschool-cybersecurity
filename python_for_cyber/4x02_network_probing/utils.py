"""Small reusable helpers for network scanning."""

import random
import time


def shuffle_ports(ports: list) -> list:
    """Shuffle and return a list of ports in place."""
    random.shuffle(ports)
    return ports


def sleep_before_scan(delay: float) -> None:
    """Pause before a scan attempt when a delay was requested."""
    if delay:
        print(f"[DEBUG] Sleeping {delay}s before next packet...")
        time.sleep(delay)


def parse_port_range(port_range: str) -> tuple:
    """Convert a port range such as '1-1000' into integer bounds."""
    try:
        start, end = (int(value) for value in port_range.split("-", 1))
    except (ValueError, TypeError):
        raise ValueError("ports must use the format START-END")

    if not (1 <= start <= end <= 65535):
        raise ValueError("ports must be between 1 and 65535")

    return start, end


def check_vulnerability(banner: str) -> str:
    """Return a vulnerability marker for a known bad service banner."""
    known_bad_signatures = ["vsftpd 2.3.4", "Apache 2.2.8"]
    normalized_banner = banner.casefold()

    if any(signature.casefold() in normalized_banner
           for signature in known_bad_signatures):
        return "[VULNERABLE]"

    return ""


def guess_service(port: int) -> str:
    """Return the common service name for a well-known port."""
    common_ports = {21: "FTP", 22: "SSH", 80: "HTTP",
                    443: "HTTPS", 3306: "MySQL"}
    service = common_ports.get(port)
    return f"{service} (Guessed)" if service else "Unknown"
