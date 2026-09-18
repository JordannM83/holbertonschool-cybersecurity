#!/bin/bash
ATTACKER_IP="$1"
PID="$2"

iptables -A INPUT -s "$ATTACKER_IP" -j DROP
iptables -A OUTPUT -d "$ATTACKER_IP" -j DROP

kill -STOP "$PID"
