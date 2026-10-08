#!/usr/bin/env python3
import unittest
from contextlib import redirect_stdout
from io import StringIO

from scapy.all import IP, TCP

from sniffer import TCPProcessor


class TestTCPProcessor(unittest.TestCase):
    def test_extracts_ip_and_ports(self):
        packet = (
            IP(src="1.1.1.1", dst="2.2.2.2")
            / TCP(sport=12345, dport=80)
        )

        output = StringIO()
        with redirect_stdout(output):
            TCPProcessor().process(packet)

        self.assertIn("1.1.1.1:12345", output.getvalue())
        self.assertIn("2.2.2.2:80", output.getvalue())


if __name__ == "__main__":
    unittest.main()
