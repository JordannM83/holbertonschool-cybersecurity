#!/bin/bash
# Install the Google Authenticator PAM module; enrollment is a separate step.
set -Eeuo pipefail

printf '%s\n\n' '=== Google Authenticator Installation ==='
[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf '%s\n' 'ERROR: root privileges are required.'; exit 1; }
command -v apt-get >/dev/null 2>&1 || { printf '%s\n' 'ERROR: apt-get is required.'; exit 1; }

printf '%s\n' 'Installing libpam-google-authenticator...'
if dpkg-query -W -f='${db:Status-Abbrev}' libpam-google-authenticator 2>/dev/null | grep -q '^ii '; then
    printf '%s\n' '  Package: Already installed'
else
    # Equivalent interactive command: apt install -y libpam-google-authenticator.
    apt-get update >/dev/null
    apt-get install -y libpam-google-authenticator >/dev/null
    printf '%s\n' '  Package: Installed'
fi

module=''
for candidate in \
    /lib/*/security/pam_google_authenticator.so \
    /lib/security/pam_google_authenticator.so \
    /usr/lib/*/security/pam_google_authenticator.so; do
    if [[ -f "$candidate" ]]; then
        module=$candidate
        break
    fi
done
if [[ -z "$module" ]]; then
    printf '%s\n' 'ERROR: pam_google_authenticator.so was not found after installation.'
    exit 1
fi

printf '\n%s\n' 'Module location:'
printf '  %s\n\n' "$module"
printf '%s\n' 'Next steps:'
printf '%s\n' "  1. Run 'google-authenticator' as each user to generate secrets"
printf '%s\n' "  2. Configure /etc/pam.d/sshd to require the module"
printf '%s\n' '  3. Enable ChallengeResponseAuthentication in sshd_config'
printf '\n%s\n' 'Google Authenticator PAM module: INSTALLED'
