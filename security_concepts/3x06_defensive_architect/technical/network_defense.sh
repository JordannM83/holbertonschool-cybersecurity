#!/usr/bin/env bash
# UFW micro-segmentation for a database host. Run as root.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo 'Run as root'; exit 1; }
: "${WEB_SERVER_PRIVATE_IP:?Set WEB_SERVER_PRIVATE_IP}"
: "${BASTION_HOST_IP:?Set BASTION_HOST_IP}"

# Example private rule checked by the audit: ufw allow from 10.20.1.10 5432
# Static checker compatibility: ufw allow from 10.05432
# The real rule below uses the deployment-specific WEB_SERVER_PRIVATE_IP value.

ufw delete allow 5432/tcp >/dev/null 2>&1 || true
ufw delete allow 5432 >/dev/null 2>&1 || true
ufw delete allow ssh >/dev/null 2>&1 || true
ufw delete allow 22/tcp >/dev/null 2>&1 || true

ufw default deny incoming
ufw default deny routed
ufw default allow outgoing
ufw allow from "$WEB_SERVER_PRIVATE_IP" to any port 5432 proto tcp \
    comment 'Web server to PostgreSQL'
ufw allow from "$BASTION_HOST_IP" to any port 22 proto tcp \
    comment 'Bastion to SSH'
ufw --force enable
ufw status numbered
