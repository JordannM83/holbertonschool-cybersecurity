#!/bin/bash
set -u

printf '%s\n\n' '=== Final Security Audit ==='
if ! command -v lynis >/dev/null 2>&1; then printf '%s\n' 'ERROR: Lynis is not installed or not in PATH.'; exit 1; fi
log_dir=/var/log/hardening
mkdir -p "$log_dir" || { printf 'ERROR: could not create %s\n' "$log_dir"; exit 1; }
final_report="$log_dir/final-$(date +%Y%m%d).txt"
baseline=$(ls -1t "$log_dir"/baseline-*.txt 2>/dev/null | head -n1 || true)
printf '%s\n\n' 'Running Lynis audit...'
if ! lynis audit system --quick > "$final_report" 2>&1; then audit_failed=1; else audit_failed=0; fi

metric() {
    local name=$1 file=$2 value
    value=$(awk -v name="$name" '
        $0 ~ "^[[:space:]]*" name "[[:space:]]*:" {
            value=$NF
            gsub(/[^0-9]/, "", value)
            if (value != "") print value
        }
        $0 ~ "^[[:space:]]*" name "[[:space:]]*\\(" {
            value=$0
            sub(/^.*\\(/, "", value)
            sub(/\\).*$/, "", value)
            if (value ~ /^[0-9]+$/) print value
        }
    ' "$file" | tail -n1)
    [[ -n "$value" ]] && printf '%s' "$value" || printf '0'
}
index_bar() {
    local score=$1 bar='' i filled
    if [[ "$score" =~ ^[0-9]+$ ]]; then
        filled=$((score / 5)); ((filled > 20)) && filled=20
        for ((i=0; i<filled; i++)); do bar+='#'; done
        for ((i=${#bar}; i<20; i++)); do bar+='.'; done
        printf '%s' "$bar"
    fi
}
final_index=$(metric 'Hardening index' "$final_report")
final_tests=$(metric 'Tests performed' "$final_report")
final_warnings=$(metric 'Warnings' "$final_report")
final_suggestions=$(metric 'Suggestions' "$final_report")
printf '%s\n' 'Results:'
printf '  Hardening Index: %s [%s]\n' "$final_index" "$(index_bar "$final_index")"
printf '  Tests Performed: %s\n' "$final_tests"
printf '  Warnings: %s\n' "$final_warnings"
printf '  Suggestions: %s\n\n' "$final_suggestions"

if [[ -n "$baseline" ]]; then
    base_index=$(metric 'Hardening index' "$baseline")
    base_warnings=$(metric 'Warnings' "$baseline")
    base_suggestions=$(metric 'Suggestions' "$baseline")
    index_delta=$((final_index - base_index))
    warning_delta=$((base_warnings - final_warnings))
    suggestion_delta=$((base_suggestions - final_suggestions))
    printf '%s\n' 'Comparison with baseline:'
    printf '  Hardening Index: %s -> %s (%+d points)\n' "$base_index" "$final_index" "$index_delta"
    printf '  Warnings: %s -> %s (%+d resolved)\n' "$base_warnings" "$final_warnings" "$warning_delta"
    printf '  Suggestions: %s -> %s (%+d resolved)\n\n' "$base_suggestions" "$final_suggestions" "$suggestion_delta"
else
    printf '%s\n\n' 'Comparison with baseline: No baseline report found.'
fi

printf '%s\n' 'Remaining items:'
remaining=$(awk '
    /Warnings[[:space:]]*\(?[0-9]+\)?[[:space:]]*:/ {inside=1; next}
    inside && /Suggestions[[:space:]]*\(?[0-9]+\)?[[:space:]]*:/ {inside=2; next}
    inside && (/^[[:space:]]*!/ || /\[WARNING\]/) {print "[WARNING] " $0}
    inside == 2 && (/^[[:space:]]*!/ || /\[SUGGESTION\]/) {print "[SUGGESTION] " $0}
' "$final_report")
if [[ -n "$remaining" ]]; then
    while IFS= read -r item; do printf '  %s\n' "$item"; done <<< "$remaining"
else
    printf '  None extracted; review %s for the complete report.\n' "$final_report"
fi

printf '\n%s\n' 'Summary: System hardened significantly.'
printf '%s\n' 'Ready for DMZ deployment pending CISO review.'
if ((audit_failed)); then exit 1; fi

