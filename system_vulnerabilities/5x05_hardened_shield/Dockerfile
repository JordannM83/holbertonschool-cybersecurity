FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="Hardened Shield" \
      org.opencontainers.image.description="Minimal Apache and OpenSSH security baseline" \
      org.opencontainers.image.vendor="Holberton School" \
      org.opencontainers.image.version="1.0" \
      org.opencontainers.image.source="holbertonschool-cybersecurity"

ENV APACHE_RUN_USER=shield \
    APACHE_RUN_GROUP=shield \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apache2 \
        ca-certificates \
        curl \
        openssh-server \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 1000 shield \
    && useradd --system --uid 1000 --gid 1000 --create-home --shell /usr/sbin/nologin shield \
    && mkdir -p /run/sshd /var/run/apache2 /var/lock/apache2 /var/www/html \
    && chown -R shield:shield /var/www/html /var/log/apache2 /var/run/apache2 /var/lock/apache2 \
    && sed -i 's/^Listen 80$/Listen 80/' /etc/apache2/ports.conf \
    && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:80>/' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's/^export APACHE_RUN_USER=.*/export APACHE_RUN_USER=shield/' /etc/apache2/envvars \
    && sed -i 's/^export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=shield/' /etc/apache2/envvars \
    && printf '%s\n' 'ServerName localhost' > /etc/apache2/conf-available/server-name.conf \
    && a2enconf server-name >/dev/null \
    && printf '%s\n' 'Hardened Shield is running.' > /var/www/html/index.html \
    && chown shield:shield /var/www/html/index.html \
    && printf '%s\n' 'Port 22' >> /etc/ssh/sshd_config \
    && printf '%s\n' 'PermitRootLogin no' >> /etc/ssh/sshd_config \
    && printf '%s\n' 'PasswordAuthentication no' >> /etc/ssh/sshd_config \
    && printf '%s\n' 'AllowUsers shield' >> /etc/ssh/sshd_config

COPY scripts/ /usr/local/lib/hardened-shield/
RUN chmod 0755 /usr/local/lib/hardened-shield/*.sh /usr/local/lib/hardened-shield/audit.py

EXPOSE 80 22

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -fsS http://127.0.0.1/ || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/lib/hardened-shield/init-services.sh"]
