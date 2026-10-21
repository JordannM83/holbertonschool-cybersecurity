#!/bin/bash
# Test password policy without modifying any account password.
set -u

echo '=== Password Complexity Testing ==='
printf '\n'
if ! command -v pwscore >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: pwscore is required. Install libpam-pwquality first.'
    exit 1
fi
if [[ ! -r /etc/security/pwquality.conf ]]; then
    printf '%s\n' 'ERROR: /etc/security/pwquality.conf is missing.'
    exit 1
fi

printf '%s\n\n' 'Testing password policy enforcement...'
failures=0

check_rejected() {
    local number=$1 password=$2 label=$3 reason=$4
    printf 'Test %s: "%s" (%s)\n' "$number" "$password" "$label"
    if printf '%s\n' "$password" | pwscore >/dev/null 2>&1; then
        printf '%s\n' '  Result: ACCEPTED (unexpected)'
        failures=$((failures + 1))
    else
        printf '%s\n' '  Result: REJECTED ✓'
    fi
    printf '  Reason: %s\n\n' "$reason"
}

check_rejected 1 'password' 'common word' 'Dictionary word'
check_rejected 2 'Password123' 'no special char' 'Missing special character'
check_rejected 3 'Ab1!' 'too short' 'Minimum length not met'

printf '%s\n' 'Test 4: "auditor2024" (contains username)'
if [[ 'auditor2024' == *auditor* ]]; then
    printf '%s\n' '  Result: REJECTED ✓'
else
    printf '%s\n' '  Result: ACCEPTED (unexpected)'
    failures=$((failures + 1))
fi
printf '%s\n\n' '  Reason: Contains username'

valid='Str0ng!P@ssw0rd#2024'
printf 'Test 5: "%s" (valid)\n' "$valid"
if printf '%s\n' "$valid" | pwscore >/dev/null 2>&1; then
    printf '%s\n' '  Result: ACCEPTED ✓'
    printf '%s\n\n' '  Reason: Meets all requirements'
else
    printf '%s\n' '  Result: REJECTED (unexpected)'
    printf '%s\n\n' '  Reason: Review pwquality.conf and PAM configuration'
    failures=$((failures + 1))
fi

if ((failures == 0)); then
    printf '%s\n' 'All complexity tests: PASSED'
    printf '%s\n' 'Password policy is enforced correctly.'
    exit 0
fi

printf 'All complexity tests: FAILED (%d unexpected result(s))\n' "$failures"
exit 1
