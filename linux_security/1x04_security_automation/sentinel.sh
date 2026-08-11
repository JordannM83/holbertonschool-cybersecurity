#!/bin/bash
[ -f "sentinel.conf" ] || exit 1; source "sentinel.conf"; [ -n "${SERVICES+x}" ] && [ -n "${FILES_TO_WATCH+x}" ] || exit 1
for service in "${SERVICES[@]}"; do
    if pgrep -f "${service}" &> /dev/null 2>&1; then
        logger "OK: ${service} is running"
    else 
        eval "${service}"
        if pgrep -f "${service}" &> /dev/null 2>&1; then
            logger "FIXED: Restarted ${service}"
        else
            logger "ERROR: ${service} start fails"
        fi
    fi
done
