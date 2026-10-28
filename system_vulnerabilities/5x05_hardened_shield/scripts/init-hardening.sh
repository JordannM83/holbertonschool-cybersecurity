#!/bin/sh
# Apply the host/container hardening baseline. Safe to run repeatedly.
set -u

LOG_DIR=${HARDENING_LOG_DIR:-/var/log/hardened-shield}
SYSCTL_FILE=/etc/sysctl.d/99-hardened-shield.conf
SSHD_CONFIG=/etc/ssh/sshd_config
BANNER_FILE=/etc/issue.net
failures=0

log() {
    printf '%s\n' "$*" | tee -a "$LOG_DIR/init-hardening.log"
}

fail() {
    log "ERROR: $*"
    failures=$((failures + 1))
}

if [ "$(id -u)" -ne 0 ]; then
    printf '%s\n' 'ERROR: init-hardening.sh must run as root.' >&2
    exit 2
fi

mkdir -p "$LOG_DIR" /etc/sysctl.d
touch "$LOG_DIR/init-hardening.log"
chmod 0750 "$LOG_DIR"
chmod 0640 "$LOG_DIR/init-hardening.log"

log '=== Hardened Shield System Hardening ==='

set_sysctl() {
    key=$1
    value=$2
    tmp=$(mktemp)
    if [ -f "$SYSCTL_FILE" ]; then
        awk -v key="$key" -v value="$value" '
            $1 == key { if (!done) { print key " = " value; done=1 }; next }
            { print }
            END { if (!done) print key " = " value }
        ' "$SYSCTL_FILE" > "$tmp"
    else
        printf '%s = %s\n' "$key" "$value" > "$tmp"
    fi
    if ! install -o root -g root -m 0644 "$tmp" "$SYSCTL_FILE"; then
        rm -f "$tmp"
        fail "could not write $SYSCTL_FILE"
    fi
    rm -f "$tmp"
}

log 'Configuring kernel parameters...'
set_sysctl net.ipv4.ip_forward 0
set_sysctl net.ipv6.conf.all.forwarding 0
set_sysctl net.ipv4.conf.all.accept_redirects 0
set_sysctl net.ipv4.conf.default.accept_redirects 0
set_sysctl net.ipv6.conf.all.accept_redirects 0
set_sysctl net.ipv6.conf.default.accept_redirects 0
set_sysctl net.ipv4.conf.all.send_redirects 0
set_sysctl net.ipv4.conf.default.send_redirects 0
set_sysctl net.ipv4.conf.all.rp_filter 1
set_sysctl net.ipv4.conf.default.rp_filter 1
set_sysctl net.ipv4.tcp_syncookies 1
set_sysctl net.ipv4.icmp_echo_ignore_broadcasts 1
set_sysctl net.ipv4.icmp_echo_ignore_all 0
set_sysctl net.ipv4.icmp_ignore_bogus_error_responses 1
set_sysctl net.ipv4.conf.all.accept_source_route 0
set_sysctl net.ipv4.conf.default.accept_source_route 0
set_sysctl net.ipv6.conf.all.accept_source_route 0
set_sysctl net.ipv6.conf.default.accept_source_route 0

if command -v sysctl >/dev/null 2>&1; then
    if sysctl -p "$SYSCTL_FILE" >>"$LOG_DIR/init-hardening.log" 2>&1; then
        log 'Kernel parameters applied.'
    else
        fail 'kernel parameters were written but could not be applied in this namespace'
    fi
else
    fail 'sysctl is not installed'
fi

log 'Configuring filesystem protections...'
mkdir -p /tmp /var/tmp /dev/shm
chmod 1777 /tmp /var/tmp /dev/shm
add_fstab_entry() {
    entry=$1
    mountpoint=$2
    if ! grep -Fq " $mountpoint " /etc/fstab 2>/dev/null; then
        printf '%s\n' "$entry" >> /etc/fstab
    fi
}
touch /etc/fstab
add_fstab_entry 'tmpfs /tmp tmpfs rw,nosuid,nodev,noexec,mode=1777 0 0' /tmp
add_fstab_entry 'tmpfs /var/tmp tmpfs rw,nosuid,nodev,noexec,mode=1777 0 0' /var/tmp
add_fstab_entry 'tmpfs /dev/shm tmpfs rw,nosuid,nodev,noexec,mode=1777 0 0' /dev/shm
log 'Filesystem configuration persisted in /etc/fstab.'

log 'Minimizing unnecessary services...'
for service in cups avahi-daemon bluetooth; do
    if command -v systemctl >/dev/null 2>&1 && \
        systemctl list-unit-files "${service}.service" 2>/dev/null | \
        grep -q "^${service}.service"; then
        systemctl disable --now "${service}.service" >/dev/null 2>&1 || \
            fail "could not disable ${service}.service"
    elif command -v service >/dev/null 2>&1 && service "$service" status >/dev/null 2>&1; then
        service "$service" stop >/dev/null 2>&1 || fail "could not stop $service"
    fi
done
log 'Unnecessary service checks complete; SSH and Apache were preserved.'

log 'Auditing SUID and SGID binaries...'
suid_report=$LOG_DIR/suid-sgid-audit.txt
{
    printf '%s\n' 'Hardened Shield SUID/SGID audit'
    printf 'Generated: %s\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '%s\n' 'SUID/SGID files:'
    find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -printf '%m %u %g %p\n' 2>/dev/null | sort
} > "$suid_report"
chmod 0640 "$suid_report"
log "SUID/SGID report written to $suid_report."

log 'Configuring legal SSH banner...'
cat > "$BANNER_FILE" <<'EOF'
=====================================
AUTHORIZED ACCESS ONLY

This system is the property of NovaTech Solutions.
Unauthorized access is prohibited and will be prosecuted.
All activities are monitored and logged.
=====================================
EOF
chown root:root "$BANNER_FILE"
chmod 0644 "$BANNER_FILE"

if [ -f "$SSHD_CONFIG" ]; then
    tmp=$(mktemp)
    awk '
        /^[[:space:]]*#?[[:space:]]*Banner[[:space:]]+/ {
            if (!done) { print "Banner /etc/issue.net"; done=1 }
            next
        }
        { print }
        END { if (!done) print "Banner /etc/issue.net" }
    ' "$SSHD_CONFIG" > "$tmp"
    if ! install -o root -g root -m 0644 "$tmp" "$SSHD_CONFIG"; then
        fail 'could not configure SSH banner'
    fi
    rm -f "$tmp"
else
    fail "$SSHD_CONFIG does not exist"
fi

if command -v sshd >/dev/null 2>&1 && ! sshd -t; then
    fail 'sshd configuration validation failed'
fi

if [ "$failures" -eq 0 ]; then
    log 'System hardening completed successfully.'
    exit 0
fi

log "System hardening completed with $failures error(s)."
exit 1
