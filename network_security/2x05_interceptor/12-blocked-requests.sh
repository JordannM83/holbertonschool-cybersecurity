#!/bin/bash
for line in /var/log/squid/access.log
    if (grep "403") then
        awk '{ print $1, $2, $4 }'
    fi
