# PySniffer

[![Python](https://img.shields.io/badge/python-3.x-blue.svg)](https://www.python.org/)

PySniffer is a Scapy-based command-line network sniffer. It identifies TCP,
UDP, and ICMP traffic, displays useful Layer 3 and Layer 4 details, searches
raw payloads, writes captures to PCAP files, and reports protocol statistics
when capture stops.

## Installation

Create and activate a virtual environment, then install Scapy:

```bash
python3 -m venv venv
source venv/bin/activate
python3 -m pip install scapy
```

Packet capture generally requires root privileges or the appropriate capture
capabilities on the selected interface.

## Usage

Run the sniffer from this directory:

```bash
sudo ./sniffer.py
```

Select an interface and BPF filter:

```bash
sudo ./sniffer.py --interface eth0 --filter "tcp port 80"
```

Available options:

| Option | Description |
| --- | --- |
| `-i`, `--interface` | Interface to capture on. |
| `-f`, `--filter` | BPF filter passed to Scapy. |
| `--write FILE` | Append captured packets to a PCAP file. |
| `-s`, `--search STRING` | Alert when STRING appears in a raw payload. |
| `-v`, `--verbose` | Print a hexadecimal dump for each recognized packet. |

Examples:

```bash
sudo ./sniffer.py --filter "icmp"
sudo ./sniffer.py -i eth0 --write capture.pcap
sudo ./sniffer.py --filter "tcp" --search "password" --verbose
```

Press `Ctrl+C` to stop capture. The sniffer closes its PCAP writer and prints
TCP, UDP, and ICMP packet counts.

## Architecture

Scapy captures packets in the capture thread and places each packet into a
thread-safe `Queue`. A separate processor thread removes packets from the
queue and performs payload searches, PCAP writing, protocol dispatch, output,
and statistics updates. This keeps console and parsing work from blocking the
capture callback during busy traffic.

Protocol-specific formatting is implemented by `TCPProcessor`,
`UDPProcessor`, and `ICMPProcessor`, all derived from `PacketProcessor`.

## Tests

Run the unit test without starting a live capture:

```bash
python3 -m unittest tests.py
```
