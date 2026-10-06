#!/usr/bin/env python3
import argparse

from scapy.all import sniff

try:
    from scapy.all import ICMP, IP, TCP, UDP
except ImportError:
    # Some test doubles expose only the sniff function.
    IP, TCP, UDP, ICMP = "IP", "TCP", "UDP", "ICMP"

try:
    from scapy.utils import PcapWriter
except ImportError:
    PcapWriter = None

try:
    from scapy.all import hexdump
except ImportError:
    hexdump = None


pcap_writer = None
verbose = False


def packet_handler(packet):
    if pcap_writer is not None:
        pcap_writer.write(packet)

    if not hasattr(packet, "haslayer"):
        return

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
    else:
        return

    if verbose and hexdump is not None:
        hexdump(packet)


def main():
    parser = argparse.ArgumentParser(
        description="Simple Scapy network sniffer"
    )
    parser.add_argument(
        "-i",
        "--interface",
        help="network interface to sniff on",
        default=None,
    )
    parser.add_argument(
        "-f",
        "--filter",
        help="BPF filter to apply",
        default=None,
    )
    parser.add_argument(
        "--write",
        help="write captured packets to a PCAP file",
        default=None,
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="print a hexadecimal dump for each packet",
    )
    args = parser.parse_args()

    global pcap_writer
    global verbose
    verbose = args.verbose
    if args.write:
        if PcapWriter is None:
            raise RuntimeError("PcapWriter is unavailable")
        pcap_writer = PcapWriter(args.write, append=True, sync=True)

    print("[INFO] PySniffer initialized.")
    try:
        sniff(
            iface=args.interface,
            filter=args.filter,
            prn=packet_handler,
        )
    except KeyboardInterrupt:
        print("[INFO] Stopping capture...")
    finally:
        if pcap_writer is not None:
            pcap_writer.close()
            pcap_writer = None


if __name__ == "__main__":
    main()
