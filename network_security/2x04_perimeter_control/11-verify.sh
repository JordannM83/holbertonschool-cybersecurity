#!/bin/bash
scp wg0.conf "$2":/etc/wireguard/wg0.conf
wg show | wg-quick up wg0
wg-quick up client
ping -c 10.200.0.1
