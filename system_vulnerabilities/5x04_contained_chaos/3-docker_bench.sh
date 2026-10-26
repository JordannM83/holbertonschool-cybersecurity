#!/bin/bash
# Run docker-bench-security and preserve its raw CIS benchmark output.
set -u

report="docker-bench-$(date +%Y%m%d-%H%M%S).log"
printf '%s\n' 'Running docker-bench-security...'

if command -v docker-bench-security >/dev/null 2>&1; then
    docker-bench-security "$@" 2>&1 | tee "$report"
    bench_status=${PIPESTATUS[0]}
elif command -v docker >/dev/null 2>&1; then
    printf '%s\n' 'Using the official docker/docker-bench-security image.'
    docker run --rm --net host --pid host --userns host \
        --cap-add audit_control \
        -e DOCKER_CONTENT_TRUST="${DOCKER_CONTENT_TRUST:-0}" \
        -v /var/lib:/var/lib:ro \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -v /etc:/etc:ro \
        -v /usr/bin/containerd:/usr/bin/containerd:ro \
        -v /usr/bin/runc:/usr/bin/runc:ro \
        docker/docker-bench-security "$@" 2>&1 | tee "$report"
    bench_status=${PIPESTATUS[0]}
else
    printf '%s\n' 'ERROR: docker-bench-security or docker is required.'
    exit 1
fi

pass_count=$(grep -cE '^\[PASS\]' "$report" 2>/dev/null || true)
warn_count=$(grep -cE '^\[WARN\]' "$report" 2>/dev/null || true)
info_count=$(grep -cE '^\[INFO\]' "$report" 2>/dev/null || true)
note_count=$(grep -cE '^\[NOTE\]' "$report" 2>/dev/null || true)
total=$((pass_count + warn_count))
if ((total > 0)); then
    score=$((pass_count * 100 / total))
else
    score=0
fi

printf '\n%s\n' 'Summary:'
printf '  PASS: %s\n  WARN: %s\n  INFO: %s\n  NOTE: %s\n' "$pass_count" "$warn_count" "$info_count" "$note_count"
if ((score < 70)); then
    printf 'Score: %s%% (CRITICAL - Do not deploy)\n' "$score"
else
    printf 'Score: %s%%\n' "$score"
fi
printf 'Raw report: %s\n' "$report"

exit "$bench_status"
