#!/usr/bin/env python3
import argparse
import requests
import subprocess
import xml.etree.ElementTree as ET


def query_virustotal(ip: str) -> dict:
    try:
        r = requests.get(f'http://localhost:5000/virustotal/{ip}')
        if r.status_code == 200:
            return r.json()
    except ConnectionError:
        return "Connection error"


def query_abuseipdb(ip: str) -> dict:
    try:
        r = requests.get(f'http://localhost:5000/abuseipdb/{ip}')
        if r.status_code == 200:
            return r.json()
    except ConnectionError:
        return "Connection error"


def run_nmap(ip: str) -> str:
    s = subprocess.run(["nmap", "-p", f"22,80", ip, "-oX", "-"],
                       capture_output=True, text=True)
    if s.returncode == 0:
        return s.stdout
    else:
        raise RuntimeError(f"Nmap failed: {s.stderr}")


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


def main():
    parser = argparse.ArgumentParser(description="Build "
                                     "an IP intelligence dossier")
    parser.add_argument("ip", help="IP address to investigate")
    args = parser.parse_args()

    # Run the data sources sequentially and keep only the parsed Nmap result.
    vt_data = query_virustotal(args.ip)
    abuse_data = query_abuseipdb(args.ip)
    nmap_ports = parse_nmap_xml(run_nmap(args.ip))

    dossier = TargetDossier(args.ip, vt_data, abuse_data, nmap_ports)
    print(dossier.summary())
    return dossier


if __name__ == "__main__":
    main()
