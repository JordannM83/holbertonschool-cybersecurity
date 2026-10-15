#!/bin/bash
set -u

if [[ $# -ne 1 ]]; then printf 'Usage: %s "YYYY-MM-DD HH:MM"\n' "$(basename "$0")"; exit 2; fi
error_time=$1
error_epoch=$(date -d "$error_time" +%s 2>/dev/null || true)
if [[ ! "$error_epoch" =~ ^[0-9]+$ ]]; then printf 'ERROR: invalid timestamp: %s\n' "$error_time"; exit 2; fi

printf '%s\n\n' '=== Update Regression Analysis ==='
printf 'Searching for updates before: %s\n\n' "$error_time"
updates_file=$(mktemp)
trap 'rm -f -- "$updates_file"' EXIT
shopt -s nullglob
logs=(/var/log/dpkg.log /var/log/dpkg.log.*)
for log in "${logs[@]}"; do
    if [[ "$log" == *.gz ]]; then reader=zcat; else reader=cat; fi
    "$reader" -- "$log" 2>/dev/null | while read -r log_date log_time action package previous current remainder; do
        [[ "$action" == upgrade || "$action" == install ]] || continue
        [[ -n "$package" && -n "$previous" && -n "$current" ]] || continue
        event_epoch=$(date -d "$log_date $log_time" +%s 2>/dev/null || true)
        [[ "$event_epoch" =~ ^[0-9]+$ ]] || continue
        (( event_epoch < error_epoch && event_epoch >= error_epoch - 86400 )) || continue
        package=${package%%:*}
        printf '%s\t%s %s\t%s\t%s\t%s\n' "$event_epoch" "$log_date" "${log_time:0:5}" "$package" "$previous" "$current" >> "$updates_file"
    done
done
shopt -u nullglob

printf '%s\n' 'Updates in the last 24 hours:'
sorted=$(sort -n "$updates_file")
if [[ -n "$sorted" ]]; then
    while IFS=$'\t' read -r event_epoch display package previous current; do
        printf '  %s  %s %s -> %s\n' "$display" "$package" "$previous" "$current"
    done <<< "$sorted"
else
    printf '  No package updates found in the preceding 24 hours.\n'
fi

printf '\n%s\n' 'Timeline analysis:'
last_epoch=0; last_display=unknown; last_package=''; last_previous=''; last_current=''
if [[ -n "$sorted" ]]; then
    while IFS=$'\t' read -r event_epoch display package previous current; do
        if (( event_epoch > last_epoch )); then
            last_epoch=$event_epoch; last_display=$display; last_package=$package
            last_previous=$previous; last_current=$current
        fi
    done <<< "$sorted"
fi
if (( last_epoch > 0 )); then
    delta=$((error_epoch - last_epoch))
    printf '  Updates completed: %s\n' "${last_display#* }"
    printf '  Error first seen: %s\n' "${error_time##* }"
    printf '  Delta: %s minutes\n' "$((delta / 60))"
else
    printf '  Updates completed: unknown\n'
    printf '  Error first seen: %s\n' "${error_time##* }"
    printf '  Delta: unknown\n'
fi

if (( last_epoch > 0 )); then
    printf '\n%s\n' 'Most likely culprit:'
    printf '  PACKAGE: %s\n' "$last_package"
    if [[ "$last_package" =~ (ca-certificates|curl|openssl|libssl|gnutls|certificate) ]]; then reason='SSL-related, updated closest to error time'; else reason='updated closest to error time'; fi
    printf '  REASON: %s\n' "$reason"
    printf '  PREVIOUS: %s\n' "$last_previous"
    printf '  CURRENT: %s\n' "$last_current"
else
    printf '\n%s\n' 'Most likely culprit: None identified'
    exit 1
fi
