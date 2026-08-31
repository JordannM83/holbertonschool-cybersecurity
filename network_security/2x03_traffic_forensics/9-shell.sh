#!/bin/bash
tshark -r "$1" -Y 'tcp contains "uid=0" or tcp contains "root"' | awk '{print $5}'
