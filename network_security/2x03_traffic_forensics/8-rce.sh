#!/bin/bash
#tshark -r "$1" -Y 'frame contains "/bin/sh"' | awk '{pint $1}'
tshark -r "$1" .(/bin/sh). -T fields -e frame.number
