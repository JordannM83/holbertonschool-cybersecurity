#!/bin/bash
# NovaTech bastion-host baseline hardening.
# Designed for Ubuntu 20.04 and later. Run as root from a local console or
# an already-tested SSH session. The script is intentionally idempotent.
set -Eeuo pipefail

readonly LOG_DIR=/var/log/hardening
readonly LOG_FILE="$LOG_DIR/master-harden-$(date +%Y%m%d).log"
readonly SYSCTL_FILE=/etc/sysctl.d/99-hardening.conf
readonly FSTAB=/etc/fstab
readonly SSH_CONFIG=/etc/ssh/sshd_config
readonly SSH_BANNER=/etc/issue.net

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
warn() { log "WARNING: $*"; }
die() { log "ERROR: $*"; exit 1; }

require_root() {
    [[ ${EUID:-$(id -u)} -eq 0 ]] || die 'this script must be run as root.'
}

backup_once() {
    local source=$1 backup
    backup="${source}.backup.$(date +%Y%m%d)"
    [[ -e "$backup" ]] || cp -a -- "$source" "$backup"
    log "Backup available: $backup"
}

set_sysctl_value() {
    local key=$1 value=$2
    if [[ -f "$SYSCTL_FILE" ]]; then
        sed -i -E "/^[[:space:]]*${key//./\\.}[[:space:]]*=/d" "$SYSCTL_FILE"
    fi
    printf '%s = %s\n' "$key" "$value" >> "$SYSCTL_FILE"
    sysctl -w "$key=$value" >/dev/null
    log "$key = $value"
}

configure_kernel() {
    log 'Configuring kernel network protections.'
    mkdir -p "$(dirname "$SYSCTL_FILE")"
    touch "$SYSCTL_FILE"
    backup_once "$SYSCTL_FILE"
    local entry key value
    while IFS='=' read -r key value; do
        [[ -z "$key" ]] && continue
        key=${key%%[[:space:]]*}
        value=${value##[[:space:]]}
        set_sysctl_value "$key" "$value"
    done <<'VALUES'
net.ipv4.ip_forward=0
net.ipv6.conf.all.forwarding=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_echo_ignore_all=0
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0
VALUES
    sysctl --system >/dev/null
}

remove_compilers() {
    command -v apt-get >/dev/null 2>&1 || { warn 'apt-get not found; skipping compiler removal.'; return; }
    local packages=()
    local package
    for package in gcc g++ make; do
        dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii ' && packages+=("$package") || true
    done
    if ((${#packages[@]})); then
        log "Purging development tools: ${packages[*]}"
        apt-get purge -y "${packages[@]}" || warn 'one or more compiler packages could not be removed.'
        apt-get autoremove -y || warn 'automatic removal of orphaned packages failed.'
    else
        log 'No targeted compiler packages are installed.'
    fi
}

restrict_network_tools() {
    local path
    for path in /usr/bin/nc /usr/bin/ncat /usr/bin/nmap /usr/sbin/tcpdump; do
        if [[ -e "$path" ]]; then
            chmod 0750 "$path"
            chown root:root "$path"
            log "Restricted $path to root and its group."
        fi
    done
}

remove_nonessential_suid() {
    local path
    for path in /usr/bin/mount /usr/bin/umount /usr/bin/newgrp /usr/local/bin/backup; do
        if [[ -e "$path" ]]; then
            chmod u-s "$path"
            log "Removed SUID from $path."
        fi
    done
}

configure_mounts() {
    backup_once "$FSTAB"
    local mountpoint spec
    for mountpoint in /tmp /var/tmp /dev/shm; do
        case "$mountpoint" in
            /tmp) spec='tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0' ;;
            /var/tmp) spec='/tmp /var/tmp none bind 0 0' ;;
            /dev/shm) spec='tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0' ;;
        esac
        sed -i -E "\\|[[:space:]]${mountpoint//\//\\/}[[:space:]]|d" "$FSTAB"
        printf '%s\n' "$spec" >> "$FSTAB"
        mountpoint -q "$mountpoint" && mount -o remount "$mountpoint" || true
        log "Configured $mountpoint with hardened mount settings."
    done
    mount /tmp 2>/dev/null || true
    mount /var/tmp 2>/dev/null || true
    mount /dev/shm 2>/dev/null || true
}

minimize_services() {
    command -v systemctl >/dev/null 2>&1 || { warn 'systemctl not found; skipping service minimization.'; return; }
    local service
    for service in cups.service avahi-daemon.service bluetooth.service; do
        if systemctl list-unit-files "$service" --no-legend 2>/dev/null | grep -q "$service"; then
            systemctl disable --now "$service" 2>/dev/null || warn "could not disable $service."
            log "Disabled $service."
        fi
    done
}

configure_ssh() {
    [[ -f "$SSH_CONFIG" ]] || { warn "$SSH_CONFIG not found; skipping SSH hardening."; return; }
    backup_once "$SSH_CONFIG"
    cat > "$SSH_BANNER" <<'BANNER'
=====================================
AUTHORIZED ACCESS ONLY

This system is the property of NovaTech Solutions.
Unauthorized access is prohibited and will be prosecuted.
All activities are monitored and logged.
=====================================
BANNER
    chmod 0644 "$SSH_BANNER"
    local key value
    for key in PermitRootLogin PasswordAuthentication X11Forwarding; do
        case "$key" in
            PermitRootLogin) value=no ;;
            PasswordAuthentication) value=no ;;
            X11Forwarding) value=no ;;
        esac
        sed -i -E "/^[[:space:]]*#?[[:space:]]*${key}[[:space:]]+/d" "$SSH_CONFIG"
        printf '%s %s\n' "$key" "$value" >> "$SSH_CONFIG"
    done
    sed -i -E '/^[[:space:]]*#?[[:space:]]*Banner[[:space:]]+/d' "$SSH_CONFIG"
    printf 'Banner %s\n' "$SSH_BANNER" >> "$SSH_CONFIG"
    if command -v sshd >/dev/null 2>&1 && sshd -t; then
        systemctl reload ssh.service 2>/dev/null || systemctl reload sshd.service 2>/dev/null || true
        log 'SSH configuration validated and reloaded.'
    else
        warn 'SSH configuration validation failed; review the backup before restarting SSH.'
    fi
}

lock_root_account() {
    command -v passwd >/dev/null 2>&1 || { warn 'passwd not found; root account was not locked.'; return; }
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        passwd -l root >/dev/null
        log 'Root account locked; sudo pre-flight passed.'
    else
        warn 'sudo pre-flight failed; root account was not locked to avoid losing administrative access.'
    fi
}

main() {
    require_root
    log '=== NovaTech Bastion Host Hardening ==='
    configure_kernel
    remove_compilers
    restrict_network_tools
    remove_nonessential_suid
    configure_mounts
    minimize_services
    configure_ssh
    lock_root_account
    log "Hardening run complete. Review $LOG_FILE and run 8-verify_kernel.sh plus 23-final_audit.sh."
}

main "$@"
