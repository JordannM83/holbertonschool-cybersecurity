#!/usr/bin/env bash
# Simple least-privilege setup. Run as root.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo 'Run as root'; exit 1; }

getent group devs >/dev/null || groupadd devs
getent group ops >/dev/null || groupadd ops
getent group auditors >/dev/null || groupadd auditors

id sarah >/dev/null 2>&1 || useradd --create-home --shell /bin/bash sarah
id dave >/dev/null 2>&1 || useradd --create-home --shell /bin/bash dave
id developer >/dev/null 2>&1 || useradd --create-home --shell /bin/bash developer

for user in sarah dave developer; do
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
