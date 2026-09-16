#!/bin/bash

FILE="/etc/rsyslog.conf"
BACKUP="/etc/backup/rsyslog.conf.backup"

mkdir -p /etc/backup
cp "$FILE" "$BACKUP"

sed -i -E '/imudp/s/^[[:space:]]*#[[:space:]]*//' "$FILE"
sed -i -E '/imtcp/s/^[[:space:]]*#[[:space:]]*//' "$FILE"

rsyslogd -N1

if [ $? -eq 0 ]; then
    systemctl restart rsyslog
else
    echo "Erreur dans la configuration rsyslog."
    cp "$BACKUP" "$FILE"
    exit 1
fi
