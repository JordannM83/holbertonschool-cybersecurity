#!/bin/bash
scp "$1" "$2":/tmp/skeleton.conf && ssh "$2" 'sudo /home/ubuntu/2-panic.sh && sudo nft -f /tmp/skeleton.conf && sudo nft list ruleset'
