#!/bin/bash
grep -Rho 'dhcp-server-identifier[[:space:]]\+[0-9.]*' /var/lib/dhcp/ 2>/dev/null | tail -1 | awk '{print $2}'
