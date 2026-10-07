#!/usr/bin/env python3
import argparse

from scapy.all import sniff

try:
    from scapy.all import ICMP, IP, TCP, UDP
except ImportError:
    IP, TCP, UDP, ICMP = "IP", "TCP", "UDP", "ICMP"

try:
    from scapy.utils import PcapWriter
except ImportError:
    PcapWriter = None

try:
    from scapy.all import hexdump
except ImportError:
    hexdump = None


class Sniffer:
    def __init__(self, interface, filter_str, output_file):
        self.interface = interface
        self.filter_str = filter_str
        self.output_file = output_file
        self.verbose = False
        self.pcap_writer = None

        if output_file:
            if PcapWriter is None:
                raise RuntimeError("PcapWriter is unavailable")
            self.pcap_writer = PcapWriter(
                output_file,
                append=True,
                sync=True,
            )

    def _dump_packet_if_verbose(self, packet):
        if self.verbose and hexdump is not None:
            hexdump(packet)

    def _process_packet(self, packet):
        if self.pcap_writer is not None:
            self.pcap_writer.write(packet)

        if not hasattr(packet, "haslayer"):
            self._dump_packet_if_verbose(packet)
            return

        if not packet.haslayer(IP):
            self._dump_packet_if_verbose(packet)
            return

        ip_layer = packet[IP]

        if packet.haslayer(TCP):
            tcp_layer = packet[TCP]
            print(
                f"[TCP] {ip_layer.src}:{tcp_layer.sport} -> "
                f"{ip_layer.dst}:{tcp_layer.dport} | Flags: "
                f"{tcp_layer.flags}"
            )
        elif packet.haslayer(UDP):
            print(f"[UDP] {ip_layer.src} -> {ip_layer.dst}")
        elif packet.haslayer(ICMP):
            print(f"[ICMP] {ip_layer.src} -> {ip_layer.dst}")
        else:
            self._dump_packet_if_verbose(packet)
            return

        self._dump_packet_if_verbose(packet)

    def start(self):
        print("[INFO] PySniffer initialized.")
        try:
            sniff(
                iface=self.interface,
                filter=self.filter_str,
                prn=self._process_packet,
            )
        except KeyboardInterrupt:
            print("[INFO] Stopping capture...")
        finally:
            if self.pcap_writer is not None:
                self.pcap_writer.close()
                self.pcap_writer = None


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

    sniffer = Sniffer(args.interface, args.filter, args.write)
    sniffer.verbose = args.verbose
    sniffer.start()


if __name__ == "__main__":
    main()
