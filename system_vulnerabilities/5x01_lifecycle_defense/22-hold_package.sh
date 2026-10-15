#!/bin/bash
set -u

if [[ $# -ne 2 ]]; then printf 'Usage: %s PACKAGE "REASON"\n' "$(basename "$0")"; exit 2; fi
package=$1; reason=$2
printf '%s\n\n' '=== Package Hold ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then printf '%s\n' 'ERROR: placing a package hold requires root privileges.'; exit 1; fi
if ! command -v apt-mark >/dev/null 2>&1 || ! command -v dpkg-query >/dev/null 2>&1; then printf '%s\n' 'ERROR: apt-mark and dpkg-query are required.'; exit 1; fi

current=$(dpkg-query -W -f='${Version}' "$package" 2>/dev/null || true)
if [[ -z "$current" ]]; then printf 'ERROR: package is not installed: %s\n' "$package"; exit 1; fi
printf 'Package: %s\n' "$package"
printf 'Current version: %s (downgraded)\n\n' "$current"

printf '%s\n' 'Placing hold...'
if apt-mark hold "$package" >/dev/null; then printf '  apt-mark hold %s: Done\n\n' "$package"
else printf '  apt-mark hold %s: FAILED\n' "$package"; exit 1; fi

log=/var/log/package_holds.log
review_date=$(date -d '+30 days' +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
printf '%s\t%s\t%s\tReview by %s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$package" "$current" "$review_date" "$reason" >> "$log" || { printf 'ERROR: could not update %s\n' "$log"; exit 1; }
chmod 0640 "$log"
printf '%s\n' 'Logging hold reason...'
printf '  %s updated\n\n' "$log"

printf '%s\n' 'Hold verification:'
if apt-mark showhold 2>/dev/null | awk -v wanted="$package" '$1 == wanted {found=1} END {exit !found}'; then printf '  %s set on hold.\n\n' "$package"
else printf '  %s is not on hold.\n' "$package"; exit 1; fi

printf '%s\n' 'WARNING: This package will NOT receive automatic updates.'
printf '%s\n' '         Including security updates.'
printf '%s\n\n' '         Review required within 30 days.'
printf '%s\n' 'Hold applied successfully.'
