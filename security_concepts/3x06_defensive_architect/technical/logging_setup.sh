#!/usr/bin/env bash
# Central logging and audit configuration. Run as root.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo 'Run as root'; exit 1; }
: "${CENTRAL_LOG_SERVER_IP:?Set CENTRAL_LOG_SERVER_IP}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y rsyslog auditd audispd-plugins

cat > /etc/rsyslog.d/60-nexus-central.conf <<EOF
\$ActionQueueType LinkedList
\$ActionQueueFileName nexus_central
\$ActionResumeRetryCount -1
\$ActionQueueSaveOnShutdown on
*.crit @@${CENTRAL_LOG_SERVER_IP}:514
authpriv.* @@${CENTRAL_LOG_SERVER_IP}:514
EOF
rsyslogd -N1
systemctl enable --now rsyslog
systemctl restart rsyslog

mkdir -p /etc/audit/rules.d
cat > /etc/audit/rules.d/99-nexus.rules <<'EOF'
-w /etc/passwd -p wa -k identity_changes
-w /etc/group -p wa -k identity_changes
-w /etc/shadow -p wa -k identity_changes
-w /etc/sudoers -p wa -k privilege_changes
-w /etc/sudoers.d/ -p wa -k privilege_changes
-w /etc/ssh/sshd_config -p wa -k ssh_changes
-w /etc/hosts -p wa -k network_changes
-w /etc/crontab -p wa -k scheduled_tasks
-w /etc/systemd/system/ -p wa -k service_changes
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -k privileged_commands
-e 2
EOF

systemctl enable --now auditd
if [[ "$(auditctl -s 2>/dev/null | awk '$1 == "enabled" {print $2; exit}')" != 2 ]]; then
    augenrules --load
    auditctl -e 2
fi

echo 'Logging setup complete.'
