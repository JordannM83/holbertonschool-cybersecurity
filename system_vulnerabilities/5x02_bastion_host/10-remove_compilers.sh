#!/bin/bash
set -u

printf '%s\n\n' '=== Development Tools Removal ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then printf '%s\n' 'ERROR: removing compilers requires root privileges.'; exit 1; fi
command -v apt-get >/dev/null 2>&1 || { printf '%s\n' 'ERROR: apt-get is required.'; exit 1; }

packages=()
for package in gcc g++ make; do
    state=$(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null || true)
    if [[ "$state" == installed ]]; then packages+=("$package"); fi
done

printf '%s\n' 'Checking dependencies before removal...'
if ((${#packages[@]})); then
    simulation=$(apt-get -s remove "${packages[@]}" 2>/dev/null || true)
    for package in gcc g++ make; do
        if printf '%s\n' "${packages[@]}" | grep -qx "$package"; then
            if printf '%s\n' "$simulation" | grep -qE "^Remv[[:space:]]+$package([[:space:]]|$)"; then printf '  %s: Can be safely removed\n' "$package"; else printf '  %s: Dependency review required\n' "$package"; fi
        fi
    done
else
    printf '  No compiler packages installed\n'
fi

removed=1
if ((${#packages[@]})); then
    printf '\n%s\n' 'Removing packages...'
    if apt-get purge -y "${packages[@]}" >/dev/null 2>&1; then
        for package in "${packages[@]}"; do printf '  %s: Removed\n' "$package"; done
    else
        removed=0
        printf '  Package removal could not complete safely\n'
    fi
else
    printf '\n%s\n' 'Removing packages...'
    printf '  Nothing to remove\n'
fi

printf '\n%s\n' 'Cleanup...'
autoremove_count=0
autoremove_plan=$(apt-get -s autoremove 2>/dev/null || true)
autoremove_count=$(printf '%s\n' "$autoremove_plan" | awk '/^Remv / {n++} END {print n+0}')
apt-get autoremove -y >/dev/null 2>&1 || true
printf '  Removing orphaned dependencies...\n'
printf '  %s packages auto-removed\n' "$autoremove_count"

if (( ! removed )); then
    printf '\n%s\n' 'Restricting remaining compiler tools to root only...'
    for binary in /usr/bin/gcc /usr/bin/g++ /usr/bin/make; do
        [[ -e "$binary" ]] && chmod 0700 -- "$binary" && chown root:root -- "$binary"
    done
fi

printf '\n%s\n' 'Verification:'
remaining=0
for binary in gcc g++ make; do
    if command -v "$binary" >/dev/null 2>&1; then
        path=$(command -v "$binary")
        if [[ $(stat -c '%a' "$path" 2>/dev/null || printf 755) == 700 ]]; then printf '  %s: Root-only\n' "$binary"; else printf '  %s: Still available\n' "$binary"; remaining=1; fi
    else
        printf '  %s: Not found\n' "$binary"
    fi
done

if (( ! remaining && removed )); then printf '\n%s\n' 'Compilers removed successfully.'; exit 0; fi
if (( ! remaining )); then printf '\n%s\n' 'Compilers restricted to root successfully.'; exit 0; fi
printf '\n%s\n' 'Compiler removal/restriction incomplete.'
exit 1

