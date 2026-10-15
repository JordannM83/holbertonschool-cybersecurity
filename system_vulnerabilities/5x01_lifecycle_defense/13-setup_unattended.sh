#!/bin/bash
# Configure and enable unattended security update scheduling.
set -u

printf '%s\n\n' '=== Unattended-Upgrades Setup ==='
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '%s\n' 'ERROR: unattended-upgrades setup requires root privileges.'
    exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: apt-get is required.'
    exit 1
fi

package_state=$(dpkg-query -W -f='${db:Status-Status}' unattended-upgrades 2>/dev/null || true)
if [[ "$package_state" != installed ]]; then
    printf '%s\n' 'Installing unattended-upgrades package...'
    if ! apt-get install -y unattended-upgrades >/dev/null; then
        printf '%s\n' 'ERROR: could not install unattended-upgrades.'
        exit 1
    fi
fi

config=/etc/apt/apt.conf.d/20auto-upgrades
if [[ -f "$config" ]]; then
    backup="${config}.backup.$(date +%Y%m%d-%H%M%S)"
    cp -p -- "$config" "$backup" || { printf '%s\n' 'ERROR: could not back up periodic configuration.'; exit 1; }
fi
tmp=$(mktemp "${config}.tmp.XXXXXX") || exit 1
trap 'rm -f -- "$tmp"' EXIT
printf '%s\n' \
    'APT::Periodic::Update-Package-Lists "1";' \
    'APT::Periodic::Unattended-Upgrade "1";' \
    'APT::Periodic::Download-Upgradeable-Packages "1";' \
    'APT::Periodic::AutocleanInterval "7";' > "$tmp"
chmod 0644 "$tmp"
if ! mv -- "$tmp" "$config"; then
    printf '%s\n' 'ERROR: could not write periodic configuration.'
    exit 1
fi

printf '%s\n' 'Configuring /etc/apt/apt.conf.d/20auto-upgrades...'
printf '  APT::Periodic::Update-Package-Lists "1";\n'
printf '  APT::Periodic::Unattended-Upgrade "1";\n'
printf '  APT::Periodic::Download-Upgradeable-Packages "1";\n'
printf '  APT::Periodic::AutocleanInterval "7";\n\n'

if ! command -v systemctl >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: systemctl is required to enable the APT timers.'
    exit 1
fi
printf '%s\n' 'Enabling systemd timers...'
timer_failed=0
if systemctl enable apt-daily.timer >/dev/null 2>&1 && systemctl start apt-daily.timer >/dev/null 2>&1; then printf '  apt-daily.timer: Enabled\n'; else printf '  apt-daily.timer: FAILED\n'; timer_failed=1; fi
if systemctl enable apt-daily-upgrade.timer >/dev/null 2>&1 && systemctl start apt-daily-upgrade.timer >/dev/null 2>&1; then printf '  apt-daily-upgrade.timer: Enabled\n'; else printf '  apt-daily-upgrade.timer: FAILED\n'; timer_failed=1; fi

printf '\n%s\n' 'Verification:'
active='INACTIVE'
package_state=$(dpkg-query -W -f='${db:Status-Status}' unattended-upgrades 2>/dev/null || true)
if [[ "$package_state" == installed ]] && (( ! timer_failed )); then active='ACTIVE'; fi
printf '  Unattended-upgrades: %s\n' "$active"
next_run='unknown'
if next=$(systemctl show apt-daily-upgrade.timer -p NextElapseUSecRealtime --value 2>/dev/null) && [[ -n "$next" ]]; then next_run=$next; fi
printf '  Next scheduled run: %s\n' "$next_run"

if [[ "$active" == ACTIVE ]]; then
    printf '\n%s\n' 'Basic setup complete.'
    exit 0
fi
printf '\n%s\n' 'Basic setup incomplete.'
exit 1
