#!/bin/bash
VAL=$(ip route get $1 | awk '{print $2}'); [[ "$VAL" = "via" ]] && echo "REMOTE" || echo "LOCAL"
