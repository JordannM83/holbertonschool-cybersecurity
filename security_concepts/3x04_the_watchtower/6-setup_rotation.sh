#!/bin/bash

cat << 'EOF' | tee /etc/logrotate.d/secure_remote
/var/log/secure_remote.log {
    daily
    rotate 7
    compress
    missingok
}
EOF
