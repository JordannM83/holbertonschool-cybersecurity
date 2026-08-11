#!/bin/bash
[ -f "sentinel.conf" ] || exit 1; source "sentinel.conf"; [ -n "${SERVICES+x}" ] && [ -n "${FILES_TO_WATCH+x}" ] || exit 1

check_services () {
    for service in "${SERVICES[@]}"; do
        if pgrep -f "${service}" &> /dev/null; then
            echo "OK: ${service} is running"
        else 
            eval "${service}"
            if pgrep -f "${service}" &> /dev/null; then
                echo "FIXED: Restarted ${service}"
            else
                echo "ERROR: ${service} start fails" >2
            fi
        fi
    done
}

check_services
