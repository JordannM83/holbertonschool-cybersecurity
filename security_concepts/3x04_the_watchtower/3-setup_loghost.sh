#!/bin/bash

FILE="/etc/rsyslog.conf"
BACKUP="/etc/backup/rsyslog.conf.backup"

mkdir -p /etc/backup
cp "$FILE" "$BACKUP"

# Modern rsyslog syntax
sed -i 's|^#module(load="imudp")|module(load="imudp")|' "$FILE"
sed -i 's|^#input(type="imudp" port="514")|input(type="imudp" port="514")|' "$FILE"

sed -i 's|^#module(load="imtcp")|module(load="imtcp")|' "$FILE"
sed -i 's|^#input(type="imtcp" port="514")|input(type="imtcp" port="514")|' "$FILE"

# Legacy rsyslog syntax
sed -i 's|^#\$ModLoad imudp|\$ModLoad imudp|' "$FILE"
sed -i 's|^#\$UDPServerRun 514|\$UDPServerRun 514|' "$FILE"

sed -i 's|^#\$ModLoad imtcp|\$ModLoad imtcp|' "$FILE"
sed -i 's|^#\$InputTCPServerRun 514|\$InputTCPServerRun 514|' "$FILE"

rsyslogd -N1

if [ $? -eq 0 ]; then
    systemctl restart rsyslog
else
    echo "Erreur dans la configuration rsyslog."
    cp "$BACKUP" "$FILE"
    exit 1
fi
