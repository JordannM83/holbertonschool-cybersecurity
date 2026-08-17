#!/bin/bash
cidr="$1"; mask=$((0xFFFFFFFF << (32 - cidr))); printf "%d.%d.%d.%d" $((mask>>24 & 255)) $((mask>>16 & 255)) $((mask>>8 & 255)) $((mask & 255))
