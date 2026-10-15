#!/bin/bash
# Validate and recover Apache, then verify that it serves HTTP.
set -u

printf '%s\n\n' '=== Apache Recovery ==='

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: restoring Apache requires root privileges.'
    exit 1
fi

apachectl=''
for candidate in apache2ctl apachectl; do
    if command -v "$candidate" >/dev/null 2>&1; then apachectl=$candidate; break; fi
done
if [[ -z "$apachectl" ]]; then
    printf '%s\n' 'ERROR: Apache control utility was not found.'
    exit 1
fi

printf '%s\n' 'Configuration test...'
config_output=$($apachectl configtest 2>&1)
config_rc=$?
if [[ "$config_rc" -eq 0 ]]; then
    printf '  Syntax: OK\n'
else
    printf '  Syntax: FAILED\n%s\n' "$config_output"
    exit 1
fi

modules=$($apachectl -M 2>/dev/null || true)
module_names=()
for module in core php7.2 ssl rewrite; do
    if [[ "$module" == php7.2 ]]; then
        [[ "$modules" == *php*_module* ]] && module_names+=("$module")
    elif [[ "$modules" == *"${module}_module"* ]]; then
        module_names+=("$module")
    fi
done
if ((${#module_names[@]})); then
    printf '  Modules loaded: %s\n' "$(IFS=', '; printf '%s' "${module_names[*]}")"
else
    printf '  Modules loaded: none detected\n'
fi

printf '\n%s\n' 'Starting Apache service...'
service_started=0
if command -v systemctl >/dev/null 2>&1; then
    if systemctl start apache2.service; then service_started=1; fi
elif command -v service >/dev/null 2>&1; then
    if service apache2 start; then service_started=1; fi
fi
if ((service_started)); then
    printf '  apache2.service: Started\n'
else
    printf '  apache2.service: FAILED to start\n'
    exit 1
fi

printf '\n%s\n' 'Health check...'
health_ok=0
http_code='000'; response_ms='N/A'
if command -v curl >/dev/null 2>&1; then
    result=$(curl -sS -o /dev/null -w '%{http_code} %{time_total}' --max-time 10 http://localhost/ 2>/dev/null || true)
    http_code=${result%% *}
    seconds=${result#* }
    if [[ "$seconds" != "$result" && "$seconds" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        response_ms=$(awk -v t="$seconds" 'BEGIN {printf "%d", (t * 1000) + 0.5}')
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget -q -O /dev/null --timeout=10 http://localhost/; then http_code=200; fi
fi
if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then health_ok=1; fi
if ((health_ok)); then
    printf '  HTTP GET /: %s OK\n' "$http_code"
    printf '  Response time: %sms\n' "$response_ms"
else
    printf '  HTTP GET /: %s FAILED\n' "$http_code"
    exit 1
fi

printf '\n%s\n' 'Apache restored successfully.'
uptime='unknown'
if command -v systemctl >/dev/null 2>&1; then
    active_since=$(systemctl show -p ActiveEnterTimestamp --value apache2.service 2>/dev/null || true)
    if [[ -n "$active_since" ]] && command -v date >/dev/null 2>&1; then
        started_epoch=$(date -d "$active_since" +%s 2>/dev/null || true)
        now_epoch=$(date +%s)
        if [[ "$started_epoch" =~ ^[0-9]+$ ]]; then
            elapsed=$((now_epoch - started_epoch)); ((elapsed < 0)) && elapsed=0
            uptime="$((elapsed / 86400)) days, $(((elapsed % 86400) / 3600)) hours, $(((elapsed % 3600) / 60)) minutes"
        fi
    fi
fi
printf 'Service uptime: %s\n' "$uptime"
