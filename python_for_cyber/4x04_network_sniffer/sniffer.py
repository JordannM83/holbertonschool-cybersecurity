#!/usr/bin/env python3
import argparse

from scapy.all import sniff

try:
    from scapy.all import ICMP, IP, Raw, TCP, UDP
except ImportError:
    IP, TCP, UDP, ICMP, Raw = "IP", "TCP", "UDP", "ICMP", "Raw"

try:
    from scapy.utils import PcapWriter
except ImportError:
    PcapWriter = None

try:
    from scapy.all import hexdump
except ImportError:
    hexdump = None


class PacketProcessor:
    def process(self, packet):
        raise NotImplementedError


class TCPProcessor(PacketProcessor):
    def process(self, packet):
        ip_layer = packet[IP]
        tcp_layer = packet[TCP]
        source = getattr(ip_layer, "src", "?")
        destination = getattr(ip_layer, "dst", "?")
        source_port = getattr(tcp_layer, "sport", "?")
        destination_port = getattr(tcp_layer, "dport", "?")
        flags = getattr(tcp_layer, "flags", "?")
        print(
            f"[TCP] {source}:{source_port} -> "
            f"{destination}:{destination_port} | Flags: {flags}"
        )


class UDPProcessor(PacketProcessor):
    def process(self, packet):
        ip_layer = packet[IP]
        source = getattr(ip_layer, "src", "?")
        destination = getattr(ip_layer, "dst", "?")
        print(f"[UDP] {source} -> {destination}")


class ICMPProcessor(PacketProcessor):
    def process(self, packet):
        ip_layer = packet[IP]
        source = getattr(ip_layer, "src", "?")
        destination = getattr(ip_layer, "dst", "?")
        print(f"[ICMP] {source} -> {destination}")


class Sniffer:
    def __init__(self, interface, filter_str, output_file, search_str=None):
        self.interface = interface
        self.filter_str = filter_str
        self.output_file = output_file
        self.search_str = search_str
        self.search_term = search_str
        self.search = search_str
        self.verbose = False
        self.pcap_writer = None
        self.processors = (
            (TCP, TCPProcessor()),
            (UDP, UDPProcessor()),
            (ICMP, ICMPProcessor()),
        )

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

    @staticmethod
    def _has_layer(packet, layer):
        try:
            return packet.haslayer(layer)
        except (TypeError, AttributeError):
            return False

    def _search_payload(self, packet):
        """Search for a string inside packet payload."""
        search_term = self.search_str or self.search_term or self.search
        if not search_term:
            return

        payload = None

        payload_layer = packet
        while payload_layer is not None:
            payload = getattr(payload_layer, "load", None)
            if payload is not None:
                break
            next_layer = getattr(payload_layer, "payload", None)
            if next_layer is payload_layer:
                break
            payload_layer = next_layer

        if payload is None:
            for raw_key in (Raw, "Raw"):
                try:
                    raw_layer = packet[raw_key]
                    payload = getattr(raw_layer, "load", None)
                except (KeyError, TypeError, AttributeError):
                    continue
                if payload is not None:
                    break

        if payload is None:
            return

        try:
            payload_text = payload.decode(errors="ignore")
        except (AttributeError, TypeError):
            payload_text = str(payload)

        if search_term in payload_text:
            print("[ALERT] Payload Match found!")

    def _process_packet(self, packet):
        if self.pcap_writer is not None:
            self.pcap_writer.write(packet)

        self._search_payload(packet)

        if not hasattr(packet, "haslayer"):
            self._dump_packet_if_verbose(packet)
            return

        if not self._has_layer(packet, IP):
            self._dump_packet_if_verbose(packet)
            return

        for layer, processor in self.processors:
            if self._has_layer(packet, layer):
                processor.process(packet)
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
        "-s",
        "--search",
        help="search string for packet payloads",
        default=None,
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="print a hexadecimal dump for each packet",
    )
    args = parser.parse_args()

    sniffer = Sniffer(
        args.interface,
        args.filter,
        args.write,
        args.search,
    )
    sniffer.verbose = args.verbose
    sniffer.start()


if __name__ == "__main__":
    main()
