#!/bin/bash
TOOLS="tools.sh"
    if [ -f "$TOOLS" ]; then
        source "$TOOLS"
    else 
        log "$TOOLS" "Engineer" "ERROR" "File doesn't exist"
        exit 1
    fi

verified_import "../config/harden.cfg"

harden_network() {
    mkdir -p /etc/hardening/

    echo "#!/bin/bash" > "$FIREWALL"
    echo "DEFAULT_INPUT="$DEFAULT_INPUT"" >> "$FIREWALL"
    echo "DEFAULT_OUTPUT="$DEFAULT_OUTPUT"" >> "$FIREWALL"
    echo "ALLOW_TCP="$SSH_PORT"" >> "$FIREWALL"
    if ALLOW_HTTP="True"; then
        echo "ALLOW_TCP="$HTTP_PORT"" >> "$FIREWALL"
    fi
    if ALLOW_HTTPS="True"; then
        echo "ALLOW_TCP="$HTTPS_PORT"" >> "$FIREWALL"
    fi
    log "$FIREWALL" "ENGINEER" "OK" "$FIREWALL write"
}


