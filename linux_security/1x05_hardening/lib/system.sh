#!/bin/bash

harden_system () {
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" upgrade

    apt-get purge -y telnet ftp netcat-traditional
    apt update && apt install auditd -y
    apt update && apt install fail2ban -y
}
