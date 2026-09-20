#!/usr/bin/env bash
# Simple least-privilege setup. Run as root.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo 'Run as root'; exit 1; }

for group in devs ops auditors; do
    getent group "$group" >/dev/null || groupadd --system "$group"
done

for user in sarah dave developer; do
    id "$user" >/dev/null 2>&1 || useradd --create-home --shell /bin/bash "$user"
    passwd --lock "$user" >/dev/null
    home="$(getent passwd "$user" | cut -d: -f6)"
    chown "$user:$user" "$home"
    chmod 700 "$home"
done

usermod -aG devs,ops sarah
usermod -aG auditors dave
usermod -aG devs developer

cat > /usr/local/sbin/nexus-nginx-logs <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/journalctl --unit nginx.service --no-pager --lines 200
EOF
chown root:root /usr/local/sbin/nexus-nginx-logs
chmod 755 /usr/local/sbin/nexus-nginx-logs

cat > /etc/sudoers.d/nexus-rbac <<'EOF'
Cmnd_Alias NGINX_OPS = /usr/bin/systemctl restart nginx, /usr/bin/systemctl status nginx --no-pager
%ops ALL=(root) NOPASSWD: NGINX_OPS
%auditors ALL=(root) NOPASSWD: /usr/local/sbin/nexus-nginx-logs
%devs ALL=(root) !ALL
EOF
chmod 440 /etc/sudoers.d/nexus-rbac
visudo -cf /etc/sudoers.d/nexus-rbac

echo 'RBAC setup complete.'
