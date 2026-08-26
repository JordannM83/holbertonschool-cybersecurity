#!/bin/bash
sudo tcpdump -i eth0 -w capture.pcap '((icmp and host 10.0.2.2) or (tcp port 80 and host 10.0.2.15))'
