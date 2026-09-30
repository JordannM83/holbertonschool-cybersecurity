#!/usr/bin/env python3
import requests
import subprocess


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


def main():
    print(query_virustotal("1.2.3.4"))
    print(query_abuseipdb("1.2.3.4"))
    print(run_nmap("1.2.3.4"))
    return


if __name__ == "__main__":
    main()
