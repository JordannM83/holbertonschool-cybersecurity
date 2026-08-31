#!/bin/bash
#tshark -r "$1" -Y 'ip' -T fields -e frame.time -e ip.src -e ip.dst 2>/dev/null
tshark -r "$1" -Y ip.addr -T fields -e frame.time
