#!/bin/bash
scp wg0.conf "$1":/tmp/wireguard/wg0.conf
ssh "$1" 'wg-quick up wg0'
wg-quick up client
ping -c 4 10.200.0.1
wg show wg0 latest-handshakes | awk '{print $2}'
