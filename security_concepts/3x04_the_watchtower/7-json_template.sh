#!/bin/bash

# Expected JSON fields: "time" "host" "msg"

cat << 'EOF' >> /etc/rsyslog.conf
template(name="json_fmt" type="string" string="{\"time\":\"%timestamp%\", \"host\":\"%hostname%\", \"msg\":\"%msg%\"}")
EOF
