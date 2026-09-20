#!/usr/bin/env bash
# Basic Ubuntu host hardening. Run as root.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo 'Run as root'; exit 1; }
source /etc/os-release
[[ "$ID" == ubuntu ]] || { echo 'Ubuntu is required'; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y openssh-server ufw fail2ban auditd apparmor unattended-upgrades

cat > /etc/sysctl.d/99-nexus-hardening.conf <<'EOF'
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.tcp_syncookies = 1
EOF
sysctl --system >/dev/null

getent group nexus-ssh >/dev/null || groupadd --system nexus-ssh
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/99-nexus-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
PubkeyAuthentication yes
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
AllowGroups nexus-ssh
EOF
sshd -t
systemctl enable --now ssh
systemctl reload ssh

sed -i -E 's/^#?PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/; s/^#?PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/; s/^#?PASS_WARN_AGE.*/PASS_WARN_AGE 14/' /etc/login.defs
echo 'umask 027' > /etc/profile.d/99-nexus-umask.sh
chmod 644 /etc/profile.d/99-nexus-umask.sh

ufw default deny incoming
ufw default deny routed
ufw default allow outgoing
ufw delete allow ssh >/dev/null 2>&1 || true
if [[ -n "${SSH_ALLOWED_CIDR:-}" ]]; then
    ufw allow from "$SSH_ALLOWED_CIDR" to any port 22 proto tcp
fi
ufw --force enable

mkdir -p /etc/fail2ban/jail.d
cat > /etc/fail2ban/jail.d/nexus-ssh.local <<'EOF'
[sshd]
enabled = true
backend = systemd
maxretry = 5
bantime = 1h
EOF
systemctl enable --now fail2ban apparmor unattended-upgrades

mkdir -p /etc/audit/rules.d
cat > /etc/audit/rules.d/99-nexus.rules <<'EOF'
-w /etc/passwd -p wa -k identity_changes
-w /etc/group -p wa -k identity_changes
-w /etc/shadow -p wa -k identity_changes
-w /etc/sudoers -p wa -k privilege_changes
-w /etc/sudoers.d/ -p wa -k privilege_changes
-w /etc/ssh/sshd_config -p wa -k ssh_changes
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -k root_commands
-e 2
EOF
systemctl enable --now auditd
auditctl -e 2 || true

echo 'Host hardening complete.'
