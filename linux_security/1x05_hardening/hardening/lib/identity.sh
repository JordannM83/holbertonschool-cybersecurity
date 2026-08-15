#!/bin/bash

REMOVED_USERS=()

pam_module_exists() {
    find /lib /usr/lib -type f -path "*/security/$1" -print -quit 2>/dev/null | grep -q .
}

save_pam_file() {
    local temporary_file="$1"
    local target_file="$2"

    if cmp -s "$temporary_file" "$target_file"; then
        rm -f "$temporary_file"
        log "IDENTITY" "$target_file" "OK" "PAM configuration already compliant"
    elif mv "$temporary_file" "$target_file"; then
        log "IDENTITY" "$target_file" "FIXED" "PAM configuration updated"
    else
        rm -f "$temporary_file"
        log "IDENTITY" "$target_file" "ERROR" "Unable to save PAM configuration"
        return 1
    fi
}

configure_password_pam() {
    local temporary_file

    [ -f "$PAM_COMMON_PASSWORD" ] || {
        log "IDENTITY" "$PAM_COMMON_PASSWORD" "ERROR" "PAM password configuration not found"
        return 1
    }
    pam_module_exists "$PAM_PWQUALITY_MODULE" || {
        log "IDENTITY" "$PAM_PWQUALITY_MODULE" "ERROR" "Required PAM module is not installed"
        return 1
    }

    temporary_file=$(mktemp "${PAM_COMMON_PASSWORD}.tmp.XXXXXX") || return 1
    awk -v module="$PAM_PWQUALITY_MODULE" -v rule="$PAM_PWQUALITY_RULE" '
        index($0, module) { next }
        !added && $0 !~ /^[[:space:]]*#/ && index($0, "pam_unix.so") {
            print rule
            added = 1
        }
        { print }
        END { if (!added) print rule }
    ' "$PAM_COMMON_PASSWORD" > "$temporary_file" || {
        rm -f "$temporary_file"
        log "IDENTITY" "$PAM_COMMON_PASSWORD" "ERROR" "Unable to prepare PAM password policy"
        return 1
    }
    save_pam_file "$temporary_file" "$PAM_COMMON_PASSWORD"
}

configure_faillock_pam() {
    local auth_temporary
    local account_temporary

    [ -f "$PAM_COMMON_AUTH" ] && [ -f "$PAM_COMMON_ACCOUNT" ] || {
        log "IDENTITY" "PAM" "ERROR" "PAM authentication configuration not found"
        return 1
    }
    pam_module_exists "$PAM_FAILLOCK_MODULE" || {
        log "IDENTITY" "$PAM_FAILLOCK_MODULE" "ERROR" "Required PAM module is not installed"
        return 1
    }

    auth_temporary=$(mktemp "${PAM_COMMON_AUTH}.tmp.XXXXXX") || return 1
    awk -v module="$PAM_FAILLOCK_MODULE" -v preauth="$PAM_FAILLOCK_PREAUTH_RULE" -v authfail="$PAM_FAILLOCK_AUTHFAIL_RULE" '
        index($0, module) { next }
        $0 !~ /^[[:space:]]*#/ && index($0, "pam_unix.so") {
            line = $0
            sub(/success=1/, "success=2", line)
            print preauth
            print line
            print authfail
            found = 1
            next
        }
        { print }
        END { if (!found) exit 2 }
    ' "$PAM_COMMON_AUTH" > "$auth_temporary" || {
        rm -f "$auth_temporary"
        log "IDENTITY" "$PAM_COMMON_AUTH" "ERROR" "Unable to prepare PAM lockout policy"
        return 1
    }
    save_pam_file "$auth_temporary" "$PAM_COMMON_AUTH" || return 1

    account_temporary=$(mktemp "${PAM_COMMON_ACCOUNT}.tmp.XXXXXX") || return 1
    awk -v module="$PAM_FAILLOCK_MODULE" -v rule="$PAM_FAILLOCK_ACCOUNT_RULE" '
        index($0, module) { next }
        { print }
        END { print rule }
    ' "$PAM_COMMON_ACCOUNT" > "$account_temporary" || {
        rm -f "$account_temporary"
        log "IDENTITY" "$PAM_COMMON_ACCOUNT" "ERROR" "Unable to prepare PAM account policy"
        return 1
    }
    save_pam_file "$account_temporary" "$PAM_COMMON_ACCOUNT"
}

configure_password_policy() {
    take_and_replace "PASS_MIN_LEN" "$PASS_MIN_LEN" "$LOGIN_CONFIG" " " "IDENTITY" || return 1
    take_and_replace "PASS_MAX_DAYS" "$PASS_MAX_DAYS" "$LOGIN_CONFIG" " " "IDENTITY" || return 1

    take_and_replace "$PWQUALITY_MINLEN_KEY" "$PASS_MIN_LEN" "$PWQ_CONF" " = " "IDENTITY" || return 1
    take_and_replace "$PWQUALITY_UPPER_KEY" "$PWQUALITY_REQUIRED_VALUE" "$PWQ_CONF" " = " "IDENTITY" || return 1
    take_and_replace "$PWQUALITY_LOWER_KEY" "$PWQUALITY_REQUIRED_VALUE" "$PWQ_CONF" " = " "IDENTITY" || return 1
    take_and_replace "$PWQUALITY_DIGIT_KEY" "$PWQUALITY_REQUIRED_VALUE" "$PWQ_CONF" " = " "IDENTITY" || return 1
    take_and_replace "$PWQUALITY_SPECIAL_KEY" "$PWQUALITY_REQUIRED_VALUE" "$PWQ_CONF" " = " "IDENTITY" || return 1
    configure_password_pam || return 1

    log "IDENTITY" "password-policy" "OK" "Password policy configured"
}

configure_lockout_policy() {
    take_and_replace "$FAILLOCK_DENY_KEY" "$FAIL_LOCK_ATTEMPTS" "$FAILLOCK_CONF" " = " "IDENTITY" || return 1
    configure_faillock_pam || return 1
    log "IDENTITY" "account-lockout" "OK" "Failed-login lockout configured"
}

user_is_privileged() {
    local username="$1"
    local user_groups
    local privileged_group

    user_groups=$(id -nG "$username" 2>/dev/null) || return 2
    for privileged_group in "${PRIVILEGED_GROUPS[@]}"; do
        if contains "$user_groups" "$privileged_group"; then
            return 0
        fi
    done
    return 1
}

cleanup_unprivileged_users() {
    local username
    local uid
    local privilege_status

    if [ ! -r "$PASSWD_FILE" ]; then
        log "IDENTITY" "$PASSWD_FILE" "ERROR" "Unable to read account database"
        return 1
    fi

    while IFS=: read -r username _ uid _; do
        [ -n "$username" ] || continue
        [ "$uid" -gt "$MIN_USER_UID" ] 2>/dev/null || continue

        user_is_privileged "$username"
        privilege_status=$?
        case "$privilege_status" in
            0)
                log "IDENTITY" "$username" "OK" "Privileged user retained"
                ;;
            1)
                if userdel -r "$username"; then
                    REMOVED_USERS+=("$username")
                    log "IDENTITY" "$username" "FIXED" "Unprivileged user deleted"
                else
                    log "IDENTITY" "$username" "ERROR" "Unable to delete unprivileged user"
                    return 1
                fi
                ;;
            *)
                log "IDENTITY" "$username" "ERROR" "Unable to determine user groups"
                return 1
                ;;
        esac
    done < "$PASSWD_FILE"
}

lock_root_password() {
    local password_status

    password_status=$(passwd -S "$ROOT_ACCOUNT" 2>/dev/null) || {
        log "IDENTITY" "$ROOT_ACCOUNT" "ERROR" "Unable to read root password status"
        return 1
    }

    case "$password_status" in
        "$ROOT_ACCOUNT L "*|"$ROOT_ACCOUNT LK "*)
            log "IDENTITY" "$ROOT_ACCOUNT" "OK" "Root password already locked"
            ;;
        *)
            if passwd -l "$ROOT_ACCOUNT" >/dev/null 2>&1; then
                log "IDENTITY" "$ROOT_ACCOUNT" "FIXED" "Root password locked"
            else
                log "IDENTITY" "$ROOT_ACCOUNT" "ERROR" "Unable to lock root password"
                return 1
            fi
            ;;
    esac
}

harden_identity() {
    configure_password_policy || return 1
    configure_lockout_policy || return 1
    cleanup_unprivileged_users || return 1
    lock_root_password || return 1
    log "IDENTITY" "hardening" "OK" "Identity hardening completed"
}
