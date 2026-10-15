#!/bin/bash
set -u

if [[ $# -ne 1 || -z "$1" ]]; then
    printf 'Usage: %s PACKAGE\n' "$(basename "$0")"
    exit 2
fi
package=$1
if ! command -v apt-cache >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: apt-cache is required.'
    exit 1
fi
policy=$(apt-cache policy -- "$package" 2>/dev/null) || {
    printf 'ERROR: could not read policy for %s.\n' "$package"
    exit 1
}
installed=$(printf '%s\n' "$policy" | sed -n 's/^[[:space:]]*Installed: //p' | head -n1)
candidate=$(printf '%s\n' "$policy" | sed -n 's/^[[:space:]]*Candidate: //p' | head -n1)
[[ -n "$installed" ]] || installed='(none)'
[[ -n "$candidate" ]] || candidate='(none)'

printf '%s\n\n' '=== Package Policy Analysis ==='
printf 'Package: %s\n' "$package"
printf 'Installed: %s\n' "$installed"
printf 'Candidate: %s\n\n' "$candidate"
printf '%s\n' 'Available versions:'
printf '  %-25s %-8s %s\n' 'Version' 'Priority' 'Repository'

entries=$(printf '%s\n' "$policy" | awk '
    function emit() { if (version != "") printf "%s\t%s\t%s\n", version, priority, repo }
    /^[[:space:]]*Version table:/ { table=1; next }
    !table { next }
    /^[[:space:]]*\*\*\*/ { emit(); version=$2; priority=$3; repo="unknown"; next }
    /^[[:space:]]*[^[:space:]]+[[:space:]]+[0-9]+/ { emit(); version=$1; priority=$2; repo="unknown"; next }
    /^[[:space:]]+[0-9]+[[:space:]]+/ && version != "" {
        for (i=1; i<=NF; i++) if ($i ~ /^(https?|file):\/\// && i<NF) { repo=$(i+1); break }
    }
    END { emit() }
')
if [[ -n "$entries" ]]; then
    while IFS=$'\t' read -r version priority repository; do
        printf '  %-25s %-8s %s\n' "$version" "$priority" "$repository"
    done <<< "$entries"
else printf '  (no available versions)\n'; fi

security='NO'
if [[ "$installed" != '(none)' && "$candidate" != '(none)' && "$candidate" != "$installed" ]]; then
    printf '%s\n' "$entries" | grep -Eiq $'^[^\t]+\t[^\t]+\t[^\t]*security' && security='YES'
fi
delta=0
if [[ "$installed" != '(none)' && "$candidate" != '(none)' ]] && command -v dpkg >/dev/null 2>&1; then
    while IFS=$'\t' read -r version priority repository; do
        [[ -n "$version" && "$version" != "$installed" ]] || continue
        dpkg --compare-versions "$version" gt "$installed" && delta=$((delta + 1))
    done <<< "$entries"
fi

printf '\n%s\n' 'Analysis:'
printf '  Security update available: %s\n' "$security"
printf '  Version delta: %s releases behind security\n' "$delta"
if [[ "$candidate" != '(none)' && "$candidate" != "$installed" ]]; then
    printf '  Recommendation: Update to %s\n' "$candidate"
else
    printf '  Recommendation: No update required\n'
fi
