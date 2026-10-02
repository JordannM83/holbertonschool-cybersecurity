#!/usr/bin/env python3
"""Command-line entry point for the intelligence broker."""

import argparse
import asyncio

import aiohttp

from api_client import fetch_api, query_abuseipdb, query_virustotal
from models import TargetDossier
from scanner import parse_nmap_xml, run_nmap
from utils import save_json_report


async def gather_intel(ip: str, verbose: bool = False) -> TargetDossier:
    """Collect API and Nmap intelligence concurrently for an IP address."""
    timeout = aiohttp.ClientTimeout(total=10)
    semaphore = asyncio.Semaphore(5)
    async with aiohttp.ClientSession(timeout=timeout) as session:
        async with semaphore:
            vt_task = query_virustotal(session, ip)
            abuse_task = query_abuseipdb(session, ip)
            nmap_task = run_nmap(ip)
            vt_data, abuse_data, nmap_xml = await asyncio.gather(
                vt_task, abuse_task, nmap_task
            )

    if verbose:
        print("[+] Nmap finished.")
    return TargetDossier(ip, vt_data, abuse_data, parse_nmap_xml(nmap_xml))


async def collect_dossier(ip: str, verbose: bool = False) -> TargetDossier:
    """Backward-compatible name for the asynchronous collector."""
    return await gather_intel(ip, verbose)


def main():
    parser = argparse.ArgumentParser(
        description="Build an IP intelligence dossier"
    )
    parser.add_argument("ip", help="IP address to investigate")
    parser.add_argument(
        "-o", "--output", metavar="FILE",
        help="write the dossier as JSON to FILE",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true",
        help="show collection status messages",
    )
    args = parser.parse_args()

    if args.verbose:
        print("[+] Querying VirusTotal...")
    dossier = asyncio.run(gather_intel(args.ip, args.verbose))
    print(dossier.summary())

    if args.output:
        save_json_report(dossier, args.output)
        if args.verbose:
            print("[SUCCESS] Report generated.")
    return dossier


if __name__ == "__main__":
    main()
