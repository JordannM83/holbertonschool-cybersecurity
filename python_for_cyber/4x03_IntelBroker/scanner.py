"""Asynchronous Nmap wrapper and XML parser."""

import asyncio
import xml.etree.ElementTree as ET


async def run_nmap(ip: str) -> str:
    """Run Nmap without blocking the event loop."""
    process = await asyncio.create_subprocess_exec(
        "nmap", "-p", "22,80", ip, "-oX", "-",
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await process.communicate()
    if process.returncode == 0:
        return stdout.decode()
    raise RuntimeError(f"Nmap failed: {stderr.decode()}")


def parse_nmap_xml(xml_data: str) -> list:
    root = ET.fromstring(xml_data)
    open_ports = []
    for port in root.findall(".//host/ports/port"):
        state = port.find("state")
        if state is not None and state.get("state") == "open":
            open_ports.append(int(port.get("portid")))
    return open_ports
