#!/bin/bash
sysctl -w net.ipv4.ip_forward=1
sed -i 's/*net.ipv4.ip_forward=*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf
