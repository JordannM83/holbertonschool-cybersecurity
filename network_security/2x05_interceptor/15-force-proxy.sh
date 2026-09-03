#!/bin/bash
VPN_NET="10.200.0.0/24"
PROXY_IP="10.200.0.1"
WAN_IF="enp0s3"

nft add rule inet filter forward ip saddr "$VPN_NET" ip daddr != "$PROXY_IP" oifname "$WAN_IF" tcp dport 80 drop
nft add rule inet filter forward ip saddr "$VPN_NET" ip daddr != "$PROXY_IP" oifname "$WAN_IF" tcp dport 443 drop
nft add rule inet filter output ip saddr "$PROXY_IP" oifname "$WAN_IF" tcp dport { 80, 443 } accept
