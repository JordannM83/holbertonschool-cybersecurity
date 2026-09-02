#!/bin/bash
apt update && apt install squid
systemctl enable squid
cp --backup /etc/squid/squid.conf.bak
