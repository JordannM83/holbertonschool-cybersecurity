#!/bin/bash
tshark -r "$1" -Y "icmp and frame.len > 100" | awk '{print $3}'
