#!/usr/bin/env python3
import requests


def query_virustotal(ip: str) -> dict:
    try:
        r = requests.get(f'http://localhost:5000/virustotal/{ip}')
        if r.status_code == 200:
            return r.json()
    except ConnectionError:
        return "Connection error"


def main():
    print(query_virustotal("1.2.3.4"))
    return


if __name__ == "__main__":
    main()
