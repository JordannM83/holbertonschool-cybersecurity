#!/bin/bash

FILE="/etc/rsyslog.d/50-default.conf"

echo '*.* @127.0.0.1' >> "$FILE"

systemctl restart rsyslog

logger "Test Log Forwarding"
