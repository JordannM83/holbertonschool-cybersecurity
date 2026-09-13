#!/bin/bash
set -euo pipefail
umask 077

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Run clean.sh as root.' >&2; exit 1; }

backup_once() {
    [[ ! -e $1 || -e $1.backup ]] || cp -a -- "$1" "$1.backup"
}

# Remove the known persistence mechanism, while retaining a recoverable copy.
if [[ -e $BACKDOOR_CRON ]]; then
    backup_once "$BACKDOOR_CRON"
    rm -f -- "$BACKDOOR_CRON"
fi

# These remote web shells are not required by Finance, IT, FTP, or the database.
for service_name in $UNNECESSARY_SERVICES; do
    systemctl disable --now "$service_name" 2>/dev/null || \
        service "$service_name" stop 2>/dev/null || true
done

# A non-root key account is mandatory before root/password SSH is disabled.
key_user=
while IFS=: read -r account _ uid _ _ account_home _; do
    if [[ $uid -ge 1000 && $uid -ne 65534 && -s $account_home/.ssh/authorized_keys ]]; then
        key_user=$account
        break
    fi
done < /etc/passwd
[[ -n $key_user ]] || {
    echo 'Refusing SSH hardening: no non-root user with authorized_keys was found.' >&2
    exit 1
}

backup_once "$SSHD_CONFIG"
ssh_candidate=$(mktemp)
trap 'rm -f -- "$ssh_candidate"' EXIT
{
    cat <<'SSH'
# BEGIN LOGICORP HARDENING
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
# END LOGICORP HARDENING
SSH
    sed '/^# BEGIN LOGICORP HARDENING$/,/^# END LOGICORP HARDENING$/d' "$SSHD_CONFIG"
} > "$ssh_candidate"
sshd -t -f "$ssh_candidate"
install -m 600 "$ssh_candidate" "$SSHD_CONFIG"
if ! service ssh reload 2>/dev/null && ! service sshd reload 2>/dev/null; then
    cp -a -- "$SSHD_CONFIG.backup" "$SSHD_CONFIG"
    service ssh reload 2>/dev/null || service sshd reload 2>/dev/null || true
    exit 1
fi

# Keep Finance FTP, reject anonymous access, and require TLS for credentials/data.
[[ -f $VSFTPD_CONFIG ]] || { echo "Missing $VSFTPD_CONFIG" >&2; exit 1; }
backup_once "$VSFTPD_CONFIG"
if [[ ! -s $FTPS_CERT || ! -s $FTPS_KEY ]]; then
    install -d -m 755 "$(dirname -- "$FTPS_CERT")"
    openssl req -x509 -nodes -newkey rsa:3072 -days "$FTPS_CERT_DAYS" \
        -subj "$FTPS_CERT_SUBJECT" -keyout "$FTPS_KEY" -out "$FTPS_CERT"
    chmod 600 "$FTPS_KEY"
fi
ftp_candidate=$(mktemp)
trap 'rm -f -- "$ssh_candidate" "$ftp_candidate"' EXIT
sed -E '/^[[:space:]]*(anonymous_enable|ssl_enable|force_local_logins_ssl|force_local_data_ssl|rsa_cert_file|rsa_private_key_file|pasv_enable|pasv_min_port|pasv_max_port)=/d' \
    "$VSFTPD_CONFIG" > "$ftp_candidate"
cat >> "$ftp_candidate" <<FTP
anonymous_enable=NO
ssl_enable=YES
force_local_logins_ssl=YES
force_local_data_ssl=YES
rsa_cert_file=$FTPS_CERT
rsa_private_key_file=$FTPS_KEY
pasv_enable=YES
pasv_min_port=$FTP_PASSIVE_MIN
pasv_max_port=$FTP_PASSIVE_MAX
FTP
install -m 600 "$ftp_candidate" "$VSFTPD_CONFIG"
if ! service vsftpd restart; then
    cp -a -- "$VSFTPD_CONFIG.backup" "$VSFTPD_CONFIG"
    service vsftpd restart || true
    exit 1
fi

# Preserve firewall rules on the lab image's next startup.
backup_once "$STARTUP_SCRIPT"
if [[ ! -e $STARTUP_SCRIPT ]]; then
    printf '%s\n' '#!/bin/bash' > "$STARTUP_SCRIPT"
fi
if ! grep -Fqx "nft -f $NFTABLES_CONFIG" "$STARTUP_SCRIPT"; then
    printf '%s\n' "nft -f $NFTABLES_CONFIG" >> "$STARTUP_SCRIPT"
fi
chmod 700 "$STARTUP_SCRIPT"

echo "Hardening complete. Key-based SSH account retained: $key_user"
