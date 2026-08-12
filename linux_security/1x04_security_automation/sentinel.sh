#!/bin/bash
LOG_FILE="/var/log/sentinel.log"
[ -f "sentinel.conf" ] || exit 1; source "sentinel.conf"; [ -n "${SERVICES+x}" ] && [ -n "${FILES_TO_WATCH+x}" ] || exit 1

check_services () {
    for service in "${SERVICES[@]}"; do
        if pgrep -f "${service}" &> /dev/null; then
            echo "OK: ${service} is running"
            log "SERVICE" "$service" "OK" "${service} is running"
        else 
            eval "${service}"
            if pgrep -f "${service}" &> /dev/null; then
                echo "FIXED: Restarted ${service}"
                log "SERVICE" "$service" "FIXED" "Restarted ${service}"
            else
                echo "ERROR: ${service} start fails" >2
                log "SERVICE" "$service" "ERROR" "${service} start fails"
            fi
        fi
    done
}

check_integrity () {
    for file in "${FILES_TO_WATCH[@]}"; do
        GOLDEN="/var/backups/sentinel/$(basename "$file").gold"
        LIVE_HASH=$(md5sum "$file" | awk '{print $1}')
        GOLDEN_HASH=$(md5sum "$GOLDEN" | awk '{print $1}')
        if [ "$LIVE_HASH" = "$GOLDEN_HASH" ]; then
            echo "OK: ${file} integrity verified"
            log "INTEGRITY" "$file" "OK" "${file} integrity verified"
        else
            cp "$GOLDEN" "$file"
            echo "FIXED: Restored ${file}"
            log "INTEGRITY" "$file" "FIXED" "Restored ${file}"
        fi
    done
}

check_ports() {
    for port in $(ss -lntp | awk 'NR>1{split($4, a, ":"); print a[2]}'); do
        allowed=false
        for allowed_port in "${ALLOWED_PORTS[@]}"; do
            if [ "$port" = "$allowed_port" ]; then
                allowed=true
            fi
        done
        if [ "$allowed" = false ]; then
            ss -K sport = :$port &>/dev/null
            echo "ALERT: Killed rogue process on port $port"
            log "PORT" "$port" "ALERT" "Killed rogue process on port $port"
        fi
    done
}

log() {
    local component="$1"
    local target="$2"
    local status="$3"
    local details="$4"
    local timestamp

    timestamp=$(date -u +%FT%TZ)

    jq -nc \
        --arg timestamp "$timestamp" \
        --arg component "$component" \
        --arg target "$target" \
        --arg status "$status" \
        --arg details "$details" \
        '{
            timestamp: $timestamp,
            component: $component,
            target: $target,
            status: $status,
            details: $details
        }' >> "$LOG_FILE"
}

check_services
check_integrity
check_ports
