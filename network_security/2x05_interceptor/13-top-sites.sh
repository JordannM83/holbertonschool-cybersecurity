#!/bin/bash
awk '{print $8}' /var/log/squid/access.log | sed -E 's#^[a-zA-Z]+://([^/:]+).*#\1#' | sort -u | uniq -c | sort | head -10
