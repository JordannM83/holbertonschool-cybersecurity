#!/bin/bash
# Validate APT sources and disable only sources that cannot be used.
set -u

printf '%s\n\n' '=== APT Sources Validation ==='

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: disabling sources requires root privileges.'
    exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: apt-get is required.'
    exit 1
fi

valid_sources=0
disabled_sources=0
validation_failed=0

host_reachable() {
    local uri=$1 host
    [[ "$uri" =~ ^(https?|ftp)://([^/[:space:]]+) ]] || return 0
    host=${BASH_REMATCH[2]}
    host=${host%%:*}
    command -v getent >/dev/null 2>&1 || return 0
    getent hosts "$host" >/dev/null 2>&1
}

validate_list_file() {
    local file=$1 line uri entries=0 good=1
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//')
        [[ -z "$line" || "$line" == \#* ]] && continue
        if [[ "$line" =~ ^deb(-src)?[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+) ]]; then
            uri=${BASH_REMATCH[2]}
            if [[ ! "$uri" =~ ^(https?|ftp|file|cdrom): ]]; then good=0; fi
            if ! host_reachable "$uri"; then good=0; fi
            entries=$((entries + 1))
        else
            good=0
        fi
    done < "$file"
    SOURCE_ENTRIES=$entries
    (( entries > 0 && good ))
}

validate_deb822_file() {
    local file=$1 uri line entries=0 good=1 has_types=0 has_uris=0 has_suites=0 has_components=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//')
        [[ -z "$line" || "$line" == \#* ]] && continue
        case "$line" in
            Types:\ *|Types:\*) has_types=1 ;;
            URIs:\ *|URIs:\*)
                has_uris=1
                for uri in ${line#URIs:}; do
                    [[ "$uri" =~ ^(https?|ftp|file|cdrom): ]] || good=0
                    host_reachable "$uri" || good=0
                done
                ;;
            Suites:\ *|Suites:\*) has_suites=1 ;;
            Components:\ *|Components:\*) has_components=1 ;;
        esac
        if [[ "$line" == Suites:* ]]; then
            entries=$((entries + 1))
            [[ "$has_components" -eq 1 || "$line" == */* ]] || true
        fi
    done < "$file"
    (( has_types && has_uris && has_suites )) || good=0
    SOURCE_ENTRIES=$entries
    (( entries > 0 && good ))
}

disable_file() {
    local file=$1 target="${file}.disabled"
    if [[ -e "$target" ]]; then
        printf '    Action: Cannot rename; %s already exists\n' "$target"
        validation_failed=1
    elif mv -- "$file" "$target"; then
        printf '    Action: Renamed to %s\n' "$(basename "$target")"
        disabled_sources=$((disabled_sources + 1))
    else
        printf '    Action: FAILED to rename %s\n' "$(basename "$file")"
        validation_failed=1
    fi
}

printf '%s\n' 'Checking main sources.list...'
main=/etc/apt/sources.list
if [[ -f "$main" ]]; then
    if validate_list_file "$main"; then
        valid_sources=$((valid_sources + SOURCE_ENTRIES))
        printf '  %s entries: All valid\n' "$SOURCE_ENTRIES"
    else
        printf '  Invalid entries found; disabling them in place\n'
        tmp=$(mktemp)
        while IFS= read -r line || [[ -n "$line" ]]; do
            check=$(printf '%s' "$line" | sed 's/^[[:space:]]*//')
            line_bad=0
            if [[ -n "$check" && "$check" != \#* ]]; then
                if [[ ! "$check" =~ ^deb(-src)?[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+) ]]; then
                    line_bad=1
                elif ! host_reachable "${BASH_REMATCH[2]}"; then
                    line_bad=1
                fi
            fi
            if (( line_bad )); then
                printf '# Disabled by 3-fix_sources.sh: %s\n' "$line" >> "$tmp"
                disabled_sources=$((disabled_sources + 1))
            else
                printf '%s\n' "$line" >> "$tmp"
                [[ "$check" =~ ^deb(-src)?[[:space:]]+ ]] && valid_sources=$((valid_sources + 1))
            fi
        done < "$main"
        if ! mv -- "$tmp" "$main"; then rm -f -- "$tmp"; validation_failed=1; fi
    fi
else
    printf '  sources.list: Not present\n'
fi

printf '\n%s\n' 'Checking sources.list.d/...'
shopt -s nullglob
source_files=(/etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources)
for file in "${source_files[@]}"; do
    if [[ "$file" == *.sources ]]; then validate_deb822_file "$file"; else validate_list_file "$file"; fi
    if [[ $? -eq 0 ]]; then
        valid_sources=$((valid_sources + SOURCE_ENTRIES))
        printf '  %s: VALID\n' "$(basename "$file")"
    else
        printf '  %s: INVALID (repository not reachable or malformed)\n' "$(basename "$file")"
        disable_file "$file"
    fi
done
shopt -u nullglob

printf '\n%s\n' 'Running apt update...'
if apt-get update; then
    printf '  All repositories updated successfully.\n'
else
    printf '  Repository update failed.\n'
    validation_failed=1
fi

printf '\n%s\n' 'Summary:'
printf '  Valid sources: %s\n' "$valid_sources"
printf '  Disabled sources: %s\n' "$disabled_sources"

if (( validation_failed )); then exit 1; fi
