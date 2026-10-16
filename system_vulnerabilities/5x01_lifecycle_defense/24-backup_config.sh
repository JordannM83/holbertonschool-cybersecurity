#!/bin/bash
set -u

printf '%s\n\n' '=== Configuration Backup ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then printf '%s\n' 'ERROR: configuration backup requires root privileges.'; exit 1; fi

backup_dir=/var/backups
timestamp=$(date +%Y%m%d-%H%M%S)
archive="$backup_dir/patch-config-$timestamp.tar.gz"
manifest=$(mktemp)
trap 'rm -f -- "$manifest"' EXIT
mkdir -p "$backup_dir" || exit 1
printf '%s\n' 'Collecting configuration files...'
add_file() {
    local absolute=$1 relative=${1#/}
    [[ -f "$absolute" ]] || return 0
    printf '  %s\n' "$absolute"
    printf '%s\n' "$relative" >> "$manifest"
}
add_tree() {
    local directory=$1 file
    [[ -d "$directory" ]] || return 0
    while IFS= read -r -d '' file; do add_file "$file"; done < <(find "$directory" -type f -print0 2>/dev/null)
}
add_file /etc/apt/apt.conf.d/20auto-upgrades
add_file /etc/apt/apt.conf.d/50unattended-upgrades
add_file /etc/apt/sources.list
add_tree /etc/apt/sources.list.d
add_tree /etc/systemd/system/apt-daily.timer.d
add_tree /etc/systemd/system/apt-daily-upgrade.timer.d
add_file /var/log/package_holds.log

file_count=$(wc -l < "$manifest")
if [[ "$file_count" -eq 0 ]]; then printf '%s\n' 'ERROR: no patch-management configuration files were found.'; exit 1; fi
printf '\n%s\n' 'Creating archive...'
if ! tar -czf "$archive" -C / -T "$manifest"; then printf '%s\n' 'ERROR: archive creation failed.'; exit 1; fi
printf '  %s\n\n' "$archive"

total_bytes=0
while IFS= read -r relative; do
    size=$(stat -c '%s' "/$relative" 2>/dev/null || printf '0')
    total_bytes=$((total_bytes + size))
done < "$manifest"
if (( total_bytes >= 1024 )); then total_size="$(( (total_bytes + 1023) / 1024 ))KB"; else total_size="${total_bytes}B"; fi
printf '%s\n' 'Archive contents:'
printf '  %s files, %s total\n\n' "$file_count" "$total_size"
checksum=$(sha256sum "$archive" | awk '{print $1}')
printf 'SHA256: %s\n\n' "$checksum"
printf '%s\n' 'Backup complete.'
