#!/bin/sh
set -eu

mkdir -p /run/sshd /var/run/apache2 /var/lock/apache2
chmod 0755 /run/sshd
/usr/sbin/sshd
exec /usr/sbin/apachectl -D FOREGROUND
