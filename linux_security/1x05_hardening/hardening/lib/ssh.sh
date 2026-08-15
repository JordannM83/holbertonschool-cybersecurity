#!/bin/bash

harden_ssh() {
    if [ ! -f "$SSHD_CONFIG" ]; then
        log "SSH" "$SSHD_CONFIG" "ERROR" "SSH server configuration file not found"
        return 1
    fi

    take_and_replace "$SSH_PORT_KEY" "$SSH_PORT" "$SSHD_CONFIG" " " "SSH" '^[[:space:]]*Match([[:space:]]|$)' || return 1
    take_and_replace "$PASSWORD_AUTHENTICATION_KEY" "$PASSWORD_AUTHENTICATION_VALUE" "$SSHD_CONFIG" " " "SSH" '^[[:space:]]*Match([[:space:]]|$)' || return 1
    take_and_replace "$PUB_KEY_AUTHENTICATION_KEY" "$PUB_KEY_AUTHENTICATION_VALUE" "$SSHD_CONFIG" " " "SSH" '^[[:space:]]*Match([[:space:]]|$)' || return 1
    take_and_replace "$PERMIT_ROOT_LOGIN_KEY" "$PERMIT_ROOT_LOGIN_VALUE" "$SSHD_CONFIG" " " "SSH" '^[[:space:]]*Match([[:space:]]|$)' || return 1

    log "SSH" "$SSHD_CONFIG" "OK" "SSH hardening configuration saved"
}
