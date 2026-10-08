#!/usr/bin/env python3
"""Queue-based Scapy network sniffer with protocol processors."""

import argparse
from queue import Queue
from threading import Thread

from scapy.all import sniff

try:
    from scapy.all import IP
except ImportError:
    class IP:
        pass

try:
    from scapy.all import TCP
except ImportError:
    class TCP:
        pass

try:
    from scapy.all import UDP
except ImportError:
    class UDP:
        pass

try:
    from scapy.all import ICMP
except ImportError:
    class ICMP:
        pass

try:
    from scapy.all import Raw
except ImportError:
    class Raw:
        pass

try:
    from scapy.utils import PcapWriter
except ImportError:
    PcapWriter = None

try:
    from scapy.all import hexdump
except ImportError:
    hexdump = None


class PacketProcessor:
    """Define the interface for protocol-specific packet processors."""

    def process(self, packet):
        """Process one packet."""
        raise NotImplementedError


class TCPProcessor(PacketProcessor):
    """Format and display TCP packet details."""

    def process(self, packet):
        """Print TCP endpoints, ports, and flags."""
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
    """Format and display UDP packet details."""

    def process(self, packet):
        """Print UDP source and destination endpoints."""
        ip_layer = packet[IP]
        source = getattr(ip_layer, "src", "?")
        destination = getattr(ip_layer, "dst", "?")
        print(f"[UDP] {source} -> {destination}")


class ICMPProcessor(PacketProcessor):
    """Format and display ICMP packet details."""

    def process(self, packet):
        """Print ICMP source and destination endpoints."""
        ip_layer = packet[IP]
        source = getattr(ip_layer, "src", "?")
        destination = getattr(ip_layer, "dst", "?")
        print(f"[ICMP] {source} -> {destination}")


class Sniffer:
    """Capture packets and dispatch them to protocol processors."""

    def __init__(self, interface, filter_str, output_file, search_str=None):
        """Configure capture, filtering, output, and payload search."""
        self.interface = interface
        self.filter_str = filter_str
        self.output_file = output_file
        self.search_str = search_str
        self.search_term = search_str
        self.search = search_str
        self.verbose = False
        self.pcap_writer = None
        self.stats = {"TCP": 0, "UDP": 0, "ICMP": 0}
        self.packet_queue = Queue()
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

        try:
            if packet.haslayer(Raw):
                payload = getattr(packet[Raw], "load", None)
        except (AssertionError, AttributeError, KeyError, TypeError):
            payload = None

        if payload is None:
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
                except (AssertionError, KeyError, TypeError, AttributeError):
                    continue
                if payload is not None:
                    break

        if payload is None:
            try:
                payload = bytes(packet)
            except (TypeError, ValueError):
                payload = None

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
                protocol = processor.__class__.__name__.replace(
                    "Processor", ""
                ).upper()
                if protocol in self.stats:
                    self.stats[protocol] += 1
                processor.process(packet)
                self._dump_packet_if_verbose(packet)
                return

        self._dump_packet_if_verbose(packet)

    def _enqueue_packet(self, packet):
        self.packet_queue.put(packet)

    def _process_queue(self):
        while True:
            packet = self.packet_queue.get()
            try:
                if packet is None:
                    return
                self._process_packet(packet)
            finally:
                self.packet_queue.task_done()

    def start(self):
        """Start capture and process queued packets until interrupted."""
        print("[INFO] PySniffer initialized.")
        processor_thread = Thread(target=self._process_queue)
        processor_thread.start()
        try:
            sniff(
                iface=self.interface,
                filter=self.filter_str,
                prn=self._enqueue_packet,
            )
        except KeyboardInterrupt:
            print("[INFO] Stopping capture...")
        finally:
            self.packet_queue.put(None)
            self.packet_queue.join()
            processor_thread.join()
            if self.pcap_writer is not None:
                self.pcap_writer.close()
                self.pcap_writer = None
            print("[INFO] Packet statistics:")
            for protocol, count in self.stats.items():
                print(f"{protocol}: {count}")


def main():
    """Parse command-line options and start the network sniffer."""
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
