#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG_FILE="$SCRIPT_DIR/config/harden.cfg"
TOOLS="$SCRIPT_DIR/lib/tools.sh"

[ -f "$CONFIG_FILE" ] || { echo "Missing configuration: $CONFIG_FILE" >&2; exit 1; }
source "$CONFIG_FILE"
[ -f "$TOOLS" ] || { echo "Missing library: $TOOLS" >&2; exit 1; }
source "$TOOLS"

log "Engine" "Engineer" "OK" "Hardening framework initialized"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    log "Run" "User" "ERROR" "Script must be run as root"
    exit 1
fi

verified_import "$SCRIPT_DIR/lib/identity.sh"
verified_import "$SCRIPT_DIR/lib/network.sh"
verified_import "$SCRIPT_DIR/lib/ssh.sh"
verified_import "$SCRIPT_DIR/lib/system.sh"

harden_network
