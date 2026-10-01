#!/usr/bin/env python3
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


def main():
    print(query_virustotal("1.2.3.4"))
    print(query_abuseipdb("1.2.3.4"))
    print(run_nmap("1.2.3.4"))
    data = run_nmap("1.2.3.4")
    print(parse_nmap_xml(data))
    return


if __name__ == "__main__":
    main()
