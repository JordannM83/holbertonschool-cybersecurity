#!/bin/bash
# Downgrade one package to a version available from the configured APT cache.
set -u

if [[ $# -ne 2 ]]; then
    printf 'Usage: %s PACKAGE VERSION\n' "$(basename "$0")"
    exit 2
fi
package=$1
target_version=$2
printf '%s\n\n' '=== Package Rollback ==='

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: package rollback requires root privileges.'
    exit 1
fi
if ! command -v apt-get >/dev/null 2>&1 || ! command -v apt-cache >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: apt-get and apt-cache are required.'
    exit 1
fi

current=$(dpkg-query -W -f='${Version}' "$package" 2>/dev/null || true)
if [[ -z "$current" ]]; then
    printf 'ERROR: package is not installed: %s\n' "$package"
    exit 1
fi
printf 'Target: %s\n' "$package"
printf 'Current: %s\n' "$current"
printf 'Rollback to: %s\n\n' "$target_version"

printf '%s\n' 'Checking version availability...'
if apt-cache madison "$package" 2>/dev/null | awk -v wanted="$target_version" '$3 == wanted {found=1} END {exit !found}'; then
    printf '  Version %s found in apt cache.\n\n' "$target_version"
else
    printf '  Version %s is not available in apt cache.\n' "$target_version"
    exit 1
fi

snapshot_id="pre-rollback-$(date +%Y%m%d)"
snapshot_dir=/var/backups/apt-rollback
printf '%s\n' 'Creating system snapshot...'
if ! mkdir -p "$snapshot_dir" ||
   ! cp -a /var/lib/dpkg/status "$snapshot_dir/${snapshot_id}.dpkg-status" ||
   ! tar -czf "$snapshot_dir/${snapshot_id}.apt-config.tar.gz" /etc/apt 2>/dev/null; then
    printf '%s\n' 'ERROR: could not create pre-rollback snapshot.'
    exit 1
fi
printf '  Snapshot ID: %s\n\n' "$snapshot_id"

printf '%s\n' 'Performing downgrade...'
printf '  Removing %s (%s)...\n' "$package" "$current"
if ! apt-get install "$package=$target_version" --allow-downgrades -y; then
    printf '%s\n' 'ERROR: package rollback failed.'
    exit 1
fi

printf '\n%s\n' 'Verification:'
installed=$(dpkg-query -W -f='${Version}' "$package" 2>/dev/null || true)
printf '  Installed version: %s\n' "$installed"
if [[ "$installed" == "$target_version" ]]; then
    printf '  Downgrade: SUCCESSFUL\n'
else
    printf '  Downgrade: FAILED\n'
    exit 1
fi

printf '\n%s\n' 'Testing application...'
ssl_ok=0
if command -v curl >/dev/null 2>&1; then
    curl -fsS --max-time 10 https://example.com/ -o /dev/null 2>/dev/null && ssl_ok=1
elif command -v openssl >/dev/null 2>&1; then
    openssl s_client -connect example.com:443 -servername example.com </dev/null >/dev/null 2>&1 && ssl_ok=1
fi
if ((ssl_ok)); then
    printf '  SSL verification: WORKING\n\n'
else
    printf '  SSL verification: FAILED or unavailable\n'
    exit 1
fi
printf '%s\n' 'Rollback complete.'
