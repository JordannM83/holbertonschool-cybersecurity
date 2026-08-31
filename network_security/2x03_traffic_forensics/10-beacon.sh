#!/bin/bash
tshark -r "$1" -Y 'ip' -T fields -e frame.time_epoch -e ip.src -e ip.dst 2>/dev/null
