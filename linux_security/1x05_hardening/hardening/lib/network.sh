#!/bin/bash

# Create the persistent firewall policy and enforce IPv4 kernel settings.
harden_network() {
    mkdir -p /etc/hardening/

    echo "#!/bin/bash" > "$FIREWALL"
    echo "DEFAULT_INPUT="$DEFAULT_INPUT"" >> "$FIREWALL"
    echo "DEFAULT_OUTPUT="$DEFAULT_OUTPUT"" >> "$FIREWALL"
    echo "ALLOW_TCP="$SSH_PORT"" >> "$FIREWALL"
    if [ "$ALLOW_HTTP" = "True" ]; then
        echo "ALLOW_TCP="$HTTP_PORT"" >> "$FIREWALL"
    fi
    if [ "$ALLOW_HTTPS" = "True" ]; then
        echo "ALLOW_TCP="$HTTPS_PORT"" >> "$FIREWALL"
    fi
    log "FIREWALL" "$FIREWALL" "OK" "$FIREWALL write"

    take_and_replace "$IP_FORWARD_KEY" "$IP_FORWARD_VALUE" "$SYSCTL_FILE" || return 1
    take_and_replace "$IGNORE_PING_KEY" "$IGNORE_PING_VALUE" "$SYSCTL_FILE" || return 1
}
