#!/bin/bash
tshark -r "$1" -Y 'ip.addr == 10.10.10.50' -T fields -e frame.time 2>/dev/null | awk 'NR==1{first=$1} {last=$1} END{print first; print last}'
