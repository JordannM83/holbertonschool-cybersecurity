#!/bin/sh
# Start and verify Apache and OpenSSH for the Hardened Shield container.
set -u

failures=0
APACHE_CONTROL=/usr/sbin/apachectl
SSHD=/usr/sbin/sshd
LOG_DIR=${SERVICE_LOG_DIR:-/var/log/hardened-shield}
APACHE_LOG=$LOG_DIR/apache-startup.log

log() {
    printf '%s\n' "$*"
}
fail() {
    log "ERROR: $*"
    failures=$((failures + 1))
}

if [ "$(id -u)" -ne 0 ]; then
    printf '%s\n' 'ERROR: init-services.sh must run as root.' >&2
    exit 2
fi

mkdir -p /run/sshd /var/run/apache2 /var/lock/apache2 "$LOG_DIR"
chmod 0755 /run/sshd
touch "$APACHE_LOG"
chmod 0640 "$APACHE_LOG"

log '=== Hardened Shield Service Initialization ==='

if [ ! -x "$SSHD" ]; then
    fail 'OpenSSH server binary was not found'
elif ! "$SSHD" -t; then
    fail 'OpenSSH configuration validation failed'
else
    if ! pgrep -x sshd >/dev/null 2>&1; then
        if ! "$SSHD"; then
            fail 'could not start OpenSSH server'
        fi
    fi
    if pgrep -x sshd >/dev/null 2>&1; then
        log 'SSH server: running'
    else
        fail 'SSH server is not running'
    fi
fi

if [ ! -x "$APACHE_CONTROL" ]; then
    fail 'Apache control utility was not found'
elif ! "$APACHE_CONTROL" configtest >/dev/null 2>&1; then
    fail 'Apache configuration validation failed'
else
    apache_pid=
    started_here=0
    if pgrep -x apache2 >/dev/null 2>&1; then
        apache_pid=$(pgrep -o -x apache2 || true)
        log 'Web server: already running'
    else
        "$APACHE_CONTROL" -D FOREGROUND >"$APACHE_LOG" 2>&1 &
        apache_pid=$!
        started_here=1
        sleep 1
        if kill -0 "$apache_pid" 2>/dev/null; then
            log 'Web server: started'
        else
            fail 'could not start Apache'
        fi
    fi

    if command -v curl >/dev/null 2>&1; then
        healthy=0
        attempt=1
        while [ "$attempt" -le 10 ]; do
            if curl -fsS --max-time 2 http://127.0.0.1/ >/dev/null 2>&1; then
                healthy=1
                break
            fi
            sleep 1
            attempt=$((attempt + 1))
        done
        if [ "$healthy" -eq 1 ]; then
            log 'HTTP health check: passed'
        else
            fail 'HTTP health check failed'
        fi
    else
        fail 'curl is required for the HTTP health check'
    fi
fi

if [ "$failures" -ne 0 ]; then
    log "Service initialization failed with $failures error(s)."
    exit 1
fi
log 'Required services are running.'
log 'Apache remains in the foreground for container lifecycle management.'

if [ "${started_here:-0}" -eq 1 ]; then
    wait "$apache_pid"
else
    while pgrep -x apache2 >/dev/null 2>&1; do
        sleep 30
    done
    exit 1
fi
