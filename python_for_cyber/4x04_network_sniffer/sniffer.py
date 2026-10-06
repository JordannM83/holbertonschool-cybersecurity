#!/usr/bin/env python3
from scapy.all import ICMP, IP, TCP, UDP, sniff


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
    sniff(count=5, prn=packet_handler)


if __name__ == "__main__":
    main()
