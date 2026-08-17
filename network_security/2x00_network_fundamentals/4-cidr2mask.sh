#!/bin/bash
for i in $(echo "$1" | tr '.' ' '); do echo "ibase=2;obase=A; $i" | bc; done | awk '{printf ".%d", $1}' | cut -c2-
