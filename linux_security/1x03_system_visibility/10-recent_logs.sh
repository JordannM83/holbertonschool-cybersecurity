#!/bin/bash
awk -v d="$(date -d '30 minutes ago' '+%b %e %H:%M:%S')" '$0 >= d && /sshd/' "$1"
