#!/bin/bash
set -u

printf '%s\n\n' '=== APT/DPKG Diagnostic ==='
has() { command -v "$1" >/dev/null 2>&1; }
lock_state() {
    local p=$1
    [[ -e "$p" ]] || { printf 'OK'; return; }
    if has fuser && fuser -s "$p" 2>/dev/null; then printf 'PRESENT (active)'
    elif has lsof && lsof -t -- "$p" >/dev/null 2>&1; then printf 'PRESENT (active)'
    else printf 'PRESENT (stale)'; fi
}

printf '%s\n' 'Lock files:'
for p in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock; do
    printf '  %s: %s\n' "$p" "$(lock_state "$p")"
done
printf '\n'

pkg_count() {
    has dpkg-query || { printf '0'; return; }
    dpkg-query -W -f='${db:Status-Status}\n' 2>/dev/null | awk -v s="$1" '$1 == s {n++} END {print n+0}'
}
pkg_names() {
    has dpkg-query || return 0
    dpkg-query -W -f='${db:Status-Status} ${binary:Package}\n' 2>/dev/null | awk -v s="$1" '$1 == s {print "    - " $2}'
}

printf '%s\n' 'Package states:'
for state in half-configured half-installed config-files; do
    case "$state" in
        half-configured) label='Half-configured' ;;
        half-installed) label='Half-installed' ;;
        config-files) label='Config-files' ;;
    esac
    n=$(pkg_count "$state")
    printf '  %s: %s packages\n' "$label" "$n"
    [[ "$n" -gt 0 ]] && pkg_names "$state"
done
printf '\n'

printf '%s\n' 'APT sources:'
valid=0; invalid=0; unreachable=0; bad_files=()
files=(/etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources)
for file in "${files[@]}"; do
    [[ -f "$file" ]] || continue
    good=1
    if [[ "$file" == *.sources ]]; then
        awk 'BEGIN{RS=""; bad=0} {if ($0 !~ /(^|\n)Types:/) next; t=u=s=c=0; n=split($0,a,"\n"); for(i=1;i<=n;i++){if(a[i]~/^Types:[[:space:]]*[^[:space:]]/)t=1;if(a[i]~/^URIs:[[:space:]]*[^[:space:]]/)u=1;if(a[i]~/^Suites:[[:space:]]*[^[:space:]]/)s=1;if(a[i]~/^Components:[[:space:]]*[^[:space:]]/)c=1} if(!t||!u||!s||(!c&&$0!~/Suites:[^\n]*\/[[:space:]]*$/))bad=1} END{exit bad}' "$file" 2>/dev/null || good=0
        if has getent; then
            while IFS= read -r line; do
                [[ "$line" == URIs:* ]] || continue
                for uri in ${line#URIs:}; do
                    if [[ "$uri" =~ ^(https?|ftp)://([^/[:space:]]+) ]]; then
                        host=${BASH_REMATCH[2]}; host=${host%%:*}
                        getent hosts "$host" >/dev/null 2>&1 || unreachable=$((unreachable+1))
                    else good=0
                    fi
                done
            done < "$file"
        fi
    else
        while IFS= read -r line || [[ -n "$line" ]]; do
            line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//')
            [[ -z "$line" || "$line" == \#* ]] && continue
            if [[ ! "$line" =~ ^deb(-src)?[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+) ]]; then good=0; continue; fi
            uri=${BASH_REMATCH[2]}
            [[ "$uri" =~ ^(https?|ftp)://[^/[:space:]]+ ]] || good=0
            if [[ "$uri" =~ ^(https?|ftp)://([^/[:space:]]+) ]] && has getent; then
                host=${BASH_REMATCH[2]}; host=${host%%:*}
                getent hosts "$host" >/dev/null 2>&1 || unreachable=$((unreachable+1))
            fi
        done < "$file"
    fi
    if ((good)); then valid=$((valid+1)); else invalid=$((invalid+1)); bad_files+=("$file"); fi
done
printf '  Valid: %s\n' "$valid"
printf '  Invalid: %s' "$invalid"
if ((invalid)); then
    printf ' ('; first=1
    for file in "${bad_files[@]}"; do ((first)) || printf ', '; printf '%s' "$file"; first=0; done
    printf ')'
fi
printf '\n\n'
printf '  Unreachable endpoints: %s\n\n' "$unreachable"

last='UNKNOWN (APT history unavailable)'
if [[ -r /var/log/apt/history.log ]]; then
    transaction=$(awk 'NF {b=b $0 "\n"} !NF {x=b; b=""} END {if (b) x=b; printf "%s", x}' /var/log/apt/history.log)
    cmd=$(printf '%s' "$transaction" | awk '/^Commandline:/{x=$0} END{print x}')
    start=$(printf '%s' "$transaction" | awk '/^Start-Date:/{x=$0} END{print x}')
    end=$(printf '%s' "$transaction" | awk '/^End-Date:/{x=$0} END{print x}')
    [[ -n "$cmd" && -n "$end" ]] && last="${end#End-Date: } (COMPLETED)"
    [[ -n "$cmd" && -z "$end" ]] && last="${start#Start-Date: } (INTERRUPTED)"
fi
printf 'Last APT operation: %s\n\n' "$last"

db='CONSISTENT'; audit=''
if has dpkg; then
    audit=$(dpkg --audit 2>/dev/null || true)
    [[ -n "$audit" ]] && db='INCONSISTENT'
    [[ -d /var/lib/dpkg/updates && -n "$(find /var/lib/dpkg/updates -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null)" ]] && db='INCONSISTENT'
else db='UNKNOWN (dpkg unavailable)'; fi
printf 'DPKG database: %s\n' "$db"
[[ -n "$audit" ]] && printf '%s\n' "$audit" | sed 's/^/  /'
if [[ "$db" != CONSISTENT || "$invalid" -gt 0 || "$unreachable" -gt 0 ]]; then printf 'Action required: YES\n'; else printf 'Action required: NO\n'; fi
