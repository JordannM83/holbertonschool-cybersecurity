#!/usr/bin/env bash
# Nexus Financial host hardening for Ubuntu 20.04+.
# Run as root. Re-running this script is safe.
# Example: SSH_ALLOWED_CIDR=10.20.0.0/16 sudo ./hardening.sh

set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="nexus-hardening"
readonly CONFIG_ROOT="/etc/nexus-hardening"
readonly BACKUP_ROOT="${CONFIG_ROOT}/backups"
readonly SSH_ALLOWED_CIDR="${SSH_ALLOWED_CIDR:-}"
readonly SSH_PORT="${SSH_PORT:-22}"
readonly SSH_GROUP="nexus-ssh"

log() { printf '[%s] %s\n' "$SCRIPT_NAME" "$*"; }
warn() { printf '[%s] WARNING: %s\n' "$SCRIPT_NAME" "$*" >&2; }
die() { printf '[%s] ERROR: %s\n' "$SCRIPT_NAME" "$*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "run as root"
[[ -r /etc/os-release ]] || die "/etc/os-release is missing"
# shellcheck disable=SC1091
. /etc/os-release
[[ "${ID:-}" == "ubuntu" ]] || die "this script supports Ubuntu only"
dpkg --compare-versions "${VERSION_ID:-0}" ge "20.04" || die "Ubuntu 20.04+ required"

install -d -m 0750 "$CONFIG_ROOT" "$BACKUP_ROOT"

backup_once() {
    local source="$1"
    [[ -e "$source" ]] || return 0
    local relative="${source#/}"
    local destination="${BACKUP_ROOT}/${relative}"
    [[ -e "$destination" ]] && return 0
    install -d -m 0700 "$(dirname "$destination")"
    cp -a -- "$source" "$destination"
}

write_managed_file() {
    local destination="$1"
    local mode="$2"
    local temporary
    temporary="$(mktemp "${destination}.XXXXXX")"
    cat >"$temporary"
    chmod "$mode" "$temporary"
    chown root:root "$temporary"
    mv -f -- "$temporary" "$destination"
}

log "Installing required security packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends \
    apparmor apparmor-utils auditd fail2ban libpam-pwquality openssh-server \
    unattended-upgrades ufw

log "Creating policy groups"
for group in nexus-ssh nexus-developers nexus-ops nexus-db-read nexus-security nexus-breakglass; do
    getent group "$group" >/dev/null || groupadd --system "$group"
done

log "Applying kernel and network-safe defaults"
backup_once /etc/sysctl.d/99-nexus-hardening.conf
write_managed_file /etc/sysctl.d/99-nexus-hardening.conf 0644 <<'EOF'
# Managed by Nexus Financial hardening.sh
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
kernel.yama.ptrace_scope = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
EOF
sysctl --system >/dev/null

log "Configuring SSH for individual, attributable access"
backup_once /etc/ssh/sshd_config
install -d -m 0755 /etc/ssh/sshd_config.d
write_managed_file /etc/ssh/sshd_config.d/99-nexus-hardening.conf 0644 <<EOF
# Managed by Nexus Financial hardening.sh
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30
MaxAuthTries 4
MaxSessions 10
AllowGroups ${SSH_GROUP}
EOF
sshd -t
systemctl enable --now ssh
systemctl reload ssh

log "Applying password and shell defaults"
backup_once /etc/login.defs
for setting in \
    'PASS_MAX_DAYS 90' \
    'PASS_MIN_DAYS 1' \
    'PASS_WARN_AGE 14' \
    'UMASK 027'; do
    key="${setting%% *}"
    value="${setting#* }"
    if grep -qE "^[[:space:]]*${key}[[:space:]]" /etc/login.defs; then
        sed -i -E "s|^[[:space:]]*${key}[[:space:]].*|${key} ${value}|" /etc/login.defs
    else
        printf '%s\n' "${key} ${value}" >> /etc/login.defs
    fi
done
write_managed_file /etc/profile.d/99-nexus-umask.sh 0644 <<'EOF'
# Managed by Nexus Financial hardening.sh
umask 027
EOF

log "Configuring the host firewall"
ufw --force reset >/dev/null
ufw default deny incoming >/dev/null
ufw default deny routed >/dev/null
ufw default allow outgoing >/dev/null
if [[ -n "$SSH_ALLOWED_CIDR" ]]; then
    ufw allow from "$SSH_ALLOWED_CIDR" to any port "$SSH_PORT" proto tcp comment 'Nexus bastion or VPN SSH' >/dev/null
else
    warn "SSH_ALLOWED_CIDR is empty; no SSH firewall rule was created"
fi
ufw --force enable >/dev/null

log "Enabling brute-force protection"
install -d -m 0755 /etc/fail2ban/jail.d
write_managed_file /etc/fail2ban/jail.d/nexus-sshd.local 0644 <<'EOF'
# Managed by Nexus Financial hardening.sh
[sshd]
enabled = true
backend = systemd
maxretry = 5
findtime = 10m
bantime = 1h
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban

log "Enabling mandatory access control and unattended security updates"
systemctl enable --now apparmor
systemctl enable --now unattended-upgrades
write_managed_file /etc/apt/apt.conf.d/20auto-upgrades 0644 <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

log "Auditing identity, privilege, and security-control changes"
backup_once /etc/audit/rules.d/99-nexus-hardening.rules
write_managed_file /etc/audit/rules.d/99-nexus-hardening.rules 0640 <<'EOF'
# Managed by Nexus Financial hardening.sh
-w /etc/passwd -p wa -k identity_changes
-w /etc/group -p wa -k identity_changes
-w /etc/shadow -p wa -k identity_changes
-w /etc/sudoers -p wa -k privilege_changes
-w /etc/sudoers.d/ -p wa -k privilege_changes
-w /etc/ssh/sshd_config -p wa -k ssh_config
-w /etc/ssh/sshd_config.d/ -p wa -k ssh_config
-w /etc/ssh/authorized_keys -p wa -k ssh_keys
-w /etc/ufw/ -p wa -k firewall_changes
-a always,exit -F arch=b64 -S setuid,setgid -F auid>=1000 -F auid!=4294967295 -k privilege_use
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=4294967295 -k root_commands
EOF
augenrules --load
systemctl enable --now auditd

log "Securing permissions on authentication configuration"
chown root:root /etc/ssh/sshd_config /etc/ssh/sshd_config.d/99-nexus-hardening.conf
chmod 0644 /etc/ssh/sshd_config /etc/ssh/sshd_config.d/99-nexus-hardening.conf
chmod 0640 /etc/audit/rules.d/99-nexus-hardening.rules

log "Hardening complete"
if [[ -z "$SSH_ALLOWED_CIDR" ]]; then
    warn "Provide SSH_ALLOWED_CIDR=bastion_or_vpn_cidr before remote SSH is required"
fi
log "Verify with: sshd -T; ufw status verbose; aa-status; auditctl -l"
