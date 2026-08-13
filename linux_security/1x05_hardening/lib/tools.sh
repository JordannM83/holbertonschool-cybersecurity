#!/bin/bash

verified_import () {
    local FILE_VI="$1"
    if [ -f "$FILE_VI" ]; then
        source "$FILE_VI"
    else 
        log "$FILE_VI" "Engineer" "ERROR" "File doesn't exist"
        exit 1
    fi
}

contains() {
    local haystack="$1"
    local needle="$2"

    [[ $haystack =~ (^|[[:space:]])"$needle"($|[[:space:]]) ]]
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
