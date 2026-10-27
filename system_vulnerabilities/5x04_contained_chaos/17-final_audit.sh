#!/bin/bash

# Compare Docker Bench Security results for the vulnerable and secure images.
set -Eeuo pipefail

vulnerable_image=\${VULNERABLE_IMAGE:-devstream-vulnerable:latest}
secure_image=\${SECURE_IMAGE:-secure-python-dev:v1}
work_dir=\$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT

command -v docker >/dev/null 2>&1 || {
    printf '%s\n' 'ERROR: docker is required.'
    exit 1
}
docker image inspect "$vulnerable_image" >/dev/null 2>&1 || {
    printf 'ERROR: image not found: %s\n' "$vulnerable_image"
    exit 1
}
docker image inspect "$secure_image" >/dev/null 2>&1 || {
    printf 'ERROR: image not found: %s\n' "$secure_image"
    exit 1
}

if command -v docker-bench-security >/dev/null 2>&1; then
    bench=(docker-bench-security --no-colors)
elif [[ -x ./docker-bench-security ]]; then
    bench=(./docker-bench-security --no-colors)
else
    printf '%s\n' 'ERROR: docker-bench-security is required.'
    exit 1
fi

run_bench() {
    local report=$1
    if ! "\${bench[@]}" >"$report" 2>&1; then
        printf 'ERROR: docker-bench-security failed; see %s\n' "$report"
        exit 1
    fi
}

count_results() {
    local report=$1 result=$2
    awk -v result="$result" '
        $0 ~ "\\[" result "\\]" { count++ }
        END { print count + 0 }
    ' "$report"
}

score() {
    local pass=$1 warn=$2
    awk -v pass="$pass" -v warn="$warn" \
        'BEGIN { total = pass + warn; if (total == 0) print 0; else printf "%.0f", pass * 100 / total }'
}

run_bench "$work_dir/bench.txt"
vulnerable_pass=\$(count_results "$work_dir/bench.txt" PASS)
vulnerable_warn=\$(count_results "$work_dir/bench.txt" WARN)
secure_pass=$vulnerable_pass
secure_warn=$vulnerable_warn

# Docker Bench audits the Docker host/runtime rather than accepting an image
# argument. Use saved per-image reports when supplied for a true comparison.
if [[ -n "\${VULNERABLE_BENCH_REPORT:-}" && -r "$VULNERABLE_BENCH_REPORT" ]]; then
    vulnerable_pass=\$(count_results "$VULNERABLE_BENCH_REPORT" PASS)
    vulnerable_warn=\$(count_results "$VULNERABLE_BENCH_REPORT" WARN)
fi
if [[ -n "\${SECURE_BENCH_REPORT:-}" && -r "$SECURE_BENCH_REPORT" ]]; then
    secure_pass=\$(count_results "$SECURE_BENCH_REPORT" PASS)
    secure_warn=\$(count_results "$SECURE_BENCH_REPORT" WARN)
fi

vulnerable_score=\$(score "$vulnerable_pass" "$vulnerable_warn")
secure_score=\$(score "$secure_pass" "$secure_warn")
improvement=$((secure_score - vulnerable_score))

printf 'Vulnerable Image (%s):\n' "$vulnerable_image"
printf '  PASS: %s\n  WARN: %s\n  Score: %s%%\n' \
    "$vulnerable_pass" "$vulnerable_warn" "$vulnerable_score"
printf 'Secure Image (%s):\n' "$secure_image"
printf '  PASS: %s\n  WARN: %s\n  Score: %s%%\n' \
    "$secure_pass" "$secure_warn" "$secure_score"
printf 'Improvement: %+d percentage points\n' "$improvement"

printf '%s\n' 'Remaining warnings:'
if grep -E '^\[WARN\]|WARN[[:space:]]' "$work_dir/bench.txt" | sed 's/^/  /'; then
    :
else
    printf '%s\n' '  None reported'
fi

if (( secure_score >= 80 && secure_warn <= 5 )); then
    printf '%s\n' 'Container Security: PRODUCTION READY'
else
    printf '%s\n' 'Container Security: REVIEW REQUIRED'
    exit 1
fi
