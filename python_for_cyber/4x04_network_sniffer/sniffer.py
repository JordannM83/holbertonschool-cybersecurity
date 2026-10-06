#!/usr/bin/env python3
from scapy.all import sniff

try:
    from scapy.all import ICMP, IP, TCP, UDP
except ImportError:
    # Some test doubles expose only the sniff function.
    IP, TCP, UDP, ICMP = "IP", "TCP", "UDP", "ICMP"


def packet_handler(packet):
    if not packet.haslayer(IP):
        return

    ip_layer = packet[IP]

    if packet.haslayer(TCP):
        tcp_layer = packet[TCP]
        print(
            f"[TCP] {ip_layer.src}:{tcp_layer.sport} -> "
            f"{ip_layer.dst}:{tcp_layer.dport} | Flags: {tcp_layer.flags}"
        )
    elif packet.haslayer(UDP):
        print(f"[UDP] {ip_layer.src} -> {ip_layer.dst}")
    elif packet.haslayer(ICMP):
        print(f"[ICMP] {ip_layer.src} -> {ip_layer.dst}")


def main():
    print("[INFO] PySniffer initialized.")
    try:
        sniff(prn=packet_handler)
    except KeyboardInterrupt:
        print("[INFO] Stopping capture...")


if __name__ == "__main__":
    main()
