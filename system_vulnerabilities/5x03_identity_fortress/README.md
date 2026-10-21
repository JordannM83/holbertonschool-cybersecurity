Learning Objectives
By the end of this project, you are expected to be able to explain to anyone, without the help of Google:

PAM (Pluggable Authentication Modules):

What PAM is and how it works

The structure of /etc/pam.d/ configuration files

The four PAM module types: auth, account, password, session

How PAM stacks work (required, requisite, sufficient, optional)

Password Policies:

How to enforce password complexity with pam_pwquality

How to prevent password reuse with pam_pwhistory

The difference between password complexity and entropy

NIST SP 800-63B password guidelines

Brute-Force Defense:

How pam_faillock works to lock accounts

The difference between account lockout and IP banning

How fail2ban complements PAM-based protections

SSH Authentication:

How SSH key-based authentication works

The relationship between public and private key

How to configure SSH to require keys only

Best practices for SSH key management

Multi-Factor Authentication:

The three factors of authentication (something you know/have/are)

How TOTP (Time-based One-Time Passwords) work

How to configure Google Authenticator on Linux

How to require both keys AND TOTP for SSH

Account Lifecycle:

How to configure password aging with chage

How to manage account expiration

How to force password changes on next login