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

run_hardening_step() {
    local function_name="$1"
    local status_variable="$2"

    if "$function_name"; then
        printf -v "$status_variable" '%s' "PASS"
    else
        printf -v "$status_variable" '%s' "FAIL"
        COMPLIANCE_STATUS="FAIL"
    fi
}

run_hardening_step harden_network NETWORK_STATUS
run_hardening_step harden_ssh SSH_STATUS
run_hardening_step harden_system SYSTEM_STATUS
run_hardening_step harden_identity IDENTITY_STATUS

generate_audit_report || exit 1
[ "$COMPLIANCE_STATUS" = "PASS" ]
