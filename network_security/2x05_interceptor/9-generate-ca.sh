#!/bin/bash
mkdir -p /etc/squid/ssl_cert
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -keyout /etc/squid/ssl_cert/myCA.key -out /etc/squid/ssl_cert/myCA.crt -subj "/CN=Squid Proxy CA"
sh -c 'cat /etc/squid/ssl_cert/myCA.key /etc/squid/ssl_cert/myCA.crt > /etc/squid/ssl_cert/myCA.pem'
chmod 600 /etc/squid/ssl_cert/myCA.pem
mkdir -p /var/lib/ssl_db
/usr/lib/squid/security_file_certgen -c -s /var/lib/ssl_db -M 4MB
