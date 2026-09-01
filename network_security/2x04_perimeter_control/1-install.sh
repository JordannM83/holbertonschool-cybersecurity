#!/bin/bash
apt update && apt install nftables -y && apt install wireguard wireguard-tools && systemctl enable --no-start nftables
