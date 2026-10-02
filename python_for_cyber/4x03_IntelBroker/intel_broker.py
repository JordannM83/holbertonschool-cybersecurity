#!/usr/bin/env python3
import asyncio
import argparse
import xml.etree.ElementTree as ET
import json
import time
from pathlib import Path

import aiohttp

CACHE_FILE = Path(__file__).resolve().parent / "cache.json"
CACHE_TTL = 60 * 60
_CACHE_LOCK = asyncio.Lock()


def _load_cache() -> dict:
    try:
        with open(CACHE_FILE, "r", encoding="utf-8") as cache_file:
            data = json.load(cache_file)
            return data if isinstance(data, dict) else {}
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return {}


def _save_cache(cache: dict) -> None:
    with open(CACHE_FILE, "w", encoding="utf-8") as cache_file:
        json.dump(cache, cache_file, indent=4)
        cache_file.write("\n")


def _cache_parts(url: str):
    parts = url.rstrip("/").split("/")
    return parts[-1], parts[-2] if len(parts) > 1 else "api"


async def fetch_api(session, url: str) -> dict:
    """Fetch JSON data from an API endpoint using an aiohttp session."""
    ip, source = _cache_parts(url)
    now = time.time()

    async with _CACHE_LOCK:
        cache = _load_cache()
        ip_cache = cache.get(ip, {})
        timestamp = ip_cache.get("timestamp", 0)
        cached_data = ip_cache.get("data", {}).get(source)
        if (cached_data is not None
                and now - timestamp < CACHE_TTL):
            return cached_data

    try:
        async with session.get(url) as response:
            if response.status == 200:
                data = await response.json()
                if not isinstance(data, dict):
                    return {}

                async with _CACHE_LOCK:
                    cache = _load_cache()
                    ip_cache = cache.setdefault(ip, {})
                    api_data = ip_cache.setdefault("data", {})
                    api_data[source] = data
                    ip_cache["timestamp"] = time.time()
                    _save_cache(cache)
                return data
    except (aiohttp.ClientError, asyncio.TimeoutError):
        pass
    return {}


async def query_virustotal(session, ip: str) -> dict:
    return await fetch_api(session, f"http://localhost:5000/virustotal/{ip}")


async def query_abuseipdb(session, ip: str) -> dict:
    return await fetch_api(session, f"http://localhost:5000/abuseipdb/{ip}")


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
        port_id = port.get("portid")
        state = port.find("state")

        if state is not None and state.get("state") == "open":
            open_ports.append(int(port_id))

    return open_ports


class TargetDossier:
    """Combined intelligence collected for one target IP address."""

    # Defaults also make the required fields visible on the class itself.
    ip = ""
    vt_data = {}
    abuse_data = {}
    nmap_ports = []

    def __init__(self, ip: str = "", vt_data=None, abuse_data=None,
                 nmap_ports=None):
        self.ip = ip
        self.vt_data = vt_data if isinstance(vt_data, dict) else {}
        self.abuse_data = abuse_data if isinstance(abuse_data, dict) else {}
        self.nmap_ports = list(nmap_ports) if nmap_ports is not None else []

    def summary(self) -> str:
        """Return a readable summary of the collected intelligence."""
        return (
            f"Target: {self.ip}\n"
            f"VirusTotal: {self.vt_data}\n"
            f"AbuseIPDB: {self.abuse_data}\n"
            f"Open ports: {self.nmap_ports}"
        )


async def gather_intel(ip: str) -> TargetDossier:
    """Collect API and Nmap intelligence concurrently for an IP address."""
    timeout = aiohttp.ClientTimeout(total=10)
    async with (aiohttp.ClientSession(timeout=timeout)
                and asyncio.Semaphore(5)) as session:
        vt_task = query_virustotal(session, ip)
        abuse_task = query_abuseipdb(session, ip)
        nmap_task = run_nmap(ip)
        vt_data, abuse_data, nmap_xml = await asyncio.gather(
            vt_task, abuse_task, nmap_task
        )

    return TargetDossier(ip, vt_data, abuse_data, parse_nmap_xml(nmap_xml))


async def collect_dossier(ip: str) -> TargetDossier:
    """Backward-compatible name for the asynchronous collector."""
    return await gather_intel(ip)


def main():
    parser = argparse.ArgumentParser(description="Build "
                                     "an IP intelligence dossier")
    parser.add_argument("ip", help="IP address to investigate")
    parser.add_argument(
        "-o", "--output", action="store_true",
        help="write the dossier as JSON to FILE",
    )
    args = parser.parse_args()

    dossier = asyncio.run(gather_intel(args.ip))
    print(dossier.summary())
    if args.output:
        with open("report.json", "w", encoding="utf-8") as f:
            json.dump(dossier.__dict__, f, indent=4)
            f.write("\n")
    return dossier


if __name__ == "__main__":
    main()
