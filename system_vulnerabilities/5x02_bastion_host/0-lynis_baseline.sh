#!/bin/bash
# Run and summarize the initial Lynis security baseline.
set -u

log_dir=/var/log/hardening
timestamp=$(date +%Y%m%d)
baseline="$log_dir/baseline-$timestamp.txt"

if ! command -v lynis >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: Lynis is not installed or not in PATH.'
    exit 1
fi
if ! mkdir -p "$log_dir"; then
    printf 'ERROR: could not create %s\n' "$log_dir"
    exit 1
fi

printf '%s\n\n' 'Running Lynis audit...'
if ! lynis audit system --quick > "$baseline" 2>&1; then
    audit_failed=1
else
    audit_failed=0
fi

hardening=$(sed -nE 's/^[[:space:]]*Hardening index[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' "$baseline" | tail -n1)
tests=$(sed -nE 's/^[[:space:]]*Tests performed[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' "$baseline" | tail -n1)
warnings=$(sed -nE 's/^[[:space:]]*Warnings[[:space:]]*\(?([0-9]+)\)?.*/\1/p' "$baseline" | tail -n1)
suggestions=$(sed -nE 's/^[[:space:]]*Suggestions[[:space:]]*\(?([0-9]+)\)?.*/\1/p' "$baseline" | tail -n1)
hardening=${hardening:-unknown}; tests=${tests:-unknown}; warnings=${warnings:-0}; suggestions=${suggestions:-0}

bar=''
if [[ "$hardening" =~ ^[0-9]+$ ]]; then
    filled=$((hardening / 5)); ((filled > 20)) && filled=20
    for ((i=0; i<filled; i++)); do bar+='#'; done
    for ((i=${#bar}; i<20; i++)); do bar+='.'; done
fi

printf '\nHardening Index: %s' "$hardening"
[[ -n "$bar" ]] && printf ' [%s]' "$bar"
printf '\nTests Performed: %s\nWarnings: %s\nSuggestions: %s\n\n' "$tests" "$warnings" "$suggestions"

printf '%s\n' 'Critical Findings:'
findings=$(awk '
    /Warnings[[:space:]]*\(?[0-9]+\)?[[:space:]]*:/ {inside=1; next}
    inside && /Suggestions[[:space:]]*\(?[0-9]+\)?[[:space:]]*:/ {inside=0}
    inside && (/^[[:space:]]*!/ || /\[WARNING\]/) {print}
' "$baseline")
if [[ -n "$findings" ]]; then
    while IFS= read -r finding; do
        finding=$(printf '%s' "$finding" | sed -E 's/^[[:space:]]*[!][[:space:]]*/[WARNING] /; s/^[[:space:]]*//')
        printf '  %s\n' "$finding"
    done <<< "$findings"
else
    printf '  No warning findings extracted. See the saved Lynis report.\n'
fi

printf '\nBaseline saved to: %s\n\n' "$baseline"
if ((audit_failed)); then
    printf '%s\n' 'WARNING: Lynis completed with a non-zero status; review the saved report.'
    exit 1
fi
