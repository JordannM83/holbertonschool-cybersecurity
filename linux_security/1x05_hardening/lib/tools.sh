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

take_and_replace() {
    local key="$1"
    local value="$2"
    local file="$3"
    local separator="${4:- = }"
    local component="${5:-SYSTEM}"
    local stop_pattern="${6:-}"
    local temporary_file

    if [ ! -f "$file" ]; then
        if touch "$file"; then
            log "$component" "$file" "FIXED" "Configuration file created"
        else
            log "$component" "$file" "ERROR" "Unable to create configuration file"
            return 1
        fi
    fi

    temporary_file=$(mktemp "${file}.tmp.XXXXXX") || {
        log "$component" "$file" "ERROR" "Unable to create temporary configuration file"
        return 1
    }

    if ! awk -v key="$key" -v value="$value" -v separator="$separator" -v stop_pattern="$stop_pattern" '
        BEGIN { replaced = 0; stopped = 0 }
        {
            if (!stopped && stop_pattern != "" && $0 ~ stop_pattern) {
                if (!replaced) {
                    print key separator value
                    replaced = 1
                }
                stopped = 1
            }

            if (stopped) {
                print
                next
            }

            line = $0
            sub(/^[[:space:]]*#[[:space:]]*/, "", line)
            sub(/^[[:space:]]*/, "", line)
            current_key = line
            sub(/[[:space:]=].*$/, "", current_key)

            if (current_key == key) {
                if (!replaced) {
                    print key separator value
                    replaced = 1
                }
                next
            }

            print
        }
        END {
            if (!replaced)
                print key separator value
        }
    ' "$file" > "$temporary_file"; then
        log "$component" "$key" "ERROR" "Unable to prepare configuration update"
        rm -f "$temporary_file"
        return 1
    fi

    if cmp -s "$temporary_file" "$file"; then
        rm -f "$temporary_file"
        log "$component" "$key" "OK" "Parameter already compliant"
    elif mv "$temporary_file" "$file"; then
        log "$component" "$key" "FIXED" "Parameter configured"
    else
        log "$component" "$key" "ERROR" "Unable to update configuration file"
        rm -f "$temporary_file"
        return 1
    fi
}
