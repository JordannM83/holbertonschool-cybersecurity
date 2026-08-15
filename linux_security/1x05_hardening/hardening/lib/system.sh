#!/bin/bash

# Update the OS, remove unwanted software, and install required security tools.
harden_system() {
    local package
    local upgrade_output
    local packages_to_install=()
    local packages_to_remove=()

    PACKAGE_UPDATE_STATUS="error"
    INSTALLED_PACKAGES=()
    REMOVED_PACKAGES=()

    for package in "${BLOATWARE_PACKAGES[@]}"; do
        if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
            packages_to_remove+=("$package")
        fi
    done

    for package in "${SECURITY_PACKAGES[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
            packages_to_install+=("$package")
        fi
    done

    if DEBIAN_FRONTEND=noninteractive apt-get update; then
        log "SYSTEM" "repositories" "OK" "Package repositories updated"
    else
        log "SYSTEM" "repositories" "ERROR" "Unable to update package repositories"
        return 1
    fi

    if upgrade_output=$(DEBIAN_FRONTEND=noninteractive apt-get -y \
        -o Dpkg::Options::="--force-confold" \
        -o Dpkg::Options::="--force-confdef" upgrade 2>&1); then
        printf '%s\n' "$upgrade_output"
        if [[ "$upgrade_output" == *"0 upgraded, 0 newly installed"* ]]; then
            PACKAGE_UPDATE_STATUS="skipped"
            log "SYSTEM" "packages" "OK" "Packages already up to date"
        else
            PACKAGE_UPDATE_STATUS="updated"
            log "SYSTEM" "packages" "OK" "System packages upgraded"
        fi
    else
        log "SYSTEM" "packages" "ERROR" "Unable to upgrade system packages"
        return 1
    fi

    if DEBIAN_FRONTEND=noninteractive apt-get purge -y "${BLOATWARE_PACKAGES[@]}"; then
        REMOVED_PACKAGES=("${packages_to_remove[@]}")
        for package in "${BLOATWARE_PACKAGES[@]}"; do
            log "SYSTEM" "$package" "OK" "Unwanted package absent"
        done
    else
        log "SYSTEM" "bloatware" "ERROR" "Unable to remove unwanted packages"
        return 1
    fi

    if DEBIAN_FRONTEND=noninteractive apt-get install -y \
        "${SECURITY_PACKAGES[@]}" "${IDENTITY_PACKAGES[@]}"; then
        INSTALLED_PACKAGES=("${packages_to_install[@]}")
        for package in "${SECURITY_PACKAGES[@]}" "${IDENTITY_PACKAGES[@]}"; do
            log "SYSTEM" "$package" "OK" "Required package installed"
        done
    else
        log "SYSTEM" "security-tools" "ERROR" "Unable to install required packages"
        return 1
    fi

    log "SYSTEM" "hardening" "OK" "System hardening completed"
}

# Convert an array into a comma-separated string for human-readable reports.
join_report_items() {
    local result=""
    local item

    for item in "$@"; do
        result+="${result:+, }$item"
    done
    printf '%s' "$result"
}

# Write the final PASS/FAIL summary and every collected warning or error.
generate_audit_report() {
    local firewall_ports="$SSH_PORT"
    local removed_users
    local warning
    local error

    [ "$ALLOW_HTTP" = "True" ] && firewall_ports+=", $HTTP_PORT"
    [ "$ALLOW_HTTPS" = "True" ] && firewall_ports+=", $HTTPS_PORT"
    removed_users=$(join_report_items "${REMOVED_USERS[@]}")

    if ! {
        printf '%s\n' "==============================================="
        printf ' HARDENING AUDIT REPORT - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
        printf '%s\n\n' "==============================================="
        if [ "$COMPLIANCE_STATUS" = "PASS" ]; then
            printf '%s\n' "[INFO] Hardening procedure completed successfully."
        else
            printf '%s\n' "[ERROR] Hardening procedure completed with errors."
        fi
        if [ "${SSH_STATUS:-FAIL}" = "PASS" ]; then
            printf '[INFO] SSH configured on port %s.\n' "$SSH_PORT"
        else
            printf '%s\n' "[ERROR] SSH configuration was not completed."
        fi
        if [ "${NETWORK_STATUS:-FAIL}" = "PASS" ]; then
            printf '[INFO] Firewall policy created: ports %s ALLOWED.\n' "$firewall_ports"
        else
            printf '%s\n' "[ERROR] Network hardening was not completed."
        fi
        if [ "${#REMOVED_USERS[@]}" -gt 0 ]; then
            printf '[INFO] %s unauthorized users removed: %s.\n' "${#REMOVED_USERS[@]}" "$removed_users"
        else
            printf '%s\n' "[INFO] 0 unauthorized users removed."
        fi
        if [ "${#INSTALLED_PACKAGES[@]}" -gt 0 ]; then
            printf '[INFO] Installed: %s.\n' "$(join_report_items "${INSTALLED_PACKAGES[@]}")"
        else
            printf '%s\n' "[INFO] Installed: none (already installed)."
        fi
        if [ "${#REMOVED_PACKAGES[@]}" -gt 0 ]; then
            printf '[INFO] Removed: %s.\n' "$(join_report_items "${REMOVED_PACKAGES[@]}")"
        else
            printf '%s\n' "[INFO] Removed: none (already absent)."
        fi
        case "${PACKAGE_UPDATE_STATUS:-error}" in
            skipped)
                printf '%s\n' "[WARN] Package updates skipped (already up to date)."
                ;;
            updated)
                printf '%s\n' "[INFO] Package updates completed successfully."
                ;;
            *)
                printf '%s\n' "[ERROR] Package updates did not complete."
                ;;
        esac
        for warning in "${REPORT_WARNINGS[@]}"; do
            printf '[WARN] %s\n' "$warning"
        done
        for error in "${REPORT_ERRORS[@]}"; do
            printf '[ERROR] %s\n' "$error"
        done
        printf '\n%s\n' "==============================================="
        printf ' COMPLIANCE STATUS: %s\n' "$COMPLIANCE_STATUS"
        printf '%s\n' "==============================================="
    } > "$AUDIT_REPORT"; then
        log "AUDIT" "$AUDIT_REPORT" "ERROR" "Unable to save audit report"
        return 1
    fi

    log "AUDIT" "$AUDIT_REPORT" "OK" "Audit report saved"
}
