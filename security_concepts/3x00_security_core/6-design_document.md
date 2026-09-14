# ApexVault Security Design Document

## Executive Summary

ApexVault is designed around three security principles: phishing-resistant identity, least-privilege authorization, and independently protected audit evidence. Passwords and SMS codes are not accepted. VIP clients authenticate with FIDO2 hardware security keys, while client files are encrypted before they leave the client-controlled trust boundary. The storage service therefore stores ciphertext and cannot expose plaintext to a SysAdmin, even when the server is fully administered. Every security-relevant event is streamed to a separate, append-only logging service with cryptographic integrity checks and immutable retention, preventing a compromised ApexVault host or administrator from erasing evidence.

## 1. Authentication Strategy

### Selected Technology

**FIDO2/WebAuthn hardware security keys** are the required primary authenticator. Each client and privileged operator receives a separately enrolled, enterprise-managed hardware token supporting a PIN and user presence or user verification. ApexVault accepts only public-key credentials registered to the correct origin and tenant. Password login, password fallback, SMS OTP, and email OTP are disabled.

For recovery, the client must pre-register two additional hardware keys through a controlled identity-proofing process. Recovery does not bypass FIDO2 and requires dual approval from the security team.

### Justification

FIDO2 is phishing-resistant because the token signs the authentication challenge only for the legitimate ApexVault origin. A cloned website cannot successfully replay the response from a different origin, and the private key never leaves the hardware token. The server stores only the public key and credential metadata.

Passwords can be guessed, reused, stolen in database breaches, or entered into a phishing site. SMS codes can be intercepted through SIM swapping, number-porting attacks, malware, or telecom compromise, and users can be tricked into disclosing them. FIDO2 removes the shared secret and binds the authentication response to the real service, substantially reducing these attack paths. Rate limiting, device enrollment controls, risk-based step-up verification, and short-lived sessions provide additional protection after authentication.

## 2. Authorization Model

### Model Selected

**Mandatory Access Control (MAC)** is the primary authorization model, implemented with storage-service isolation and mandatory policy enforcement. Each object is labeled with a tenant and sensitivity label, and the policy engine enforces that a request may access an object only when the authenticated client context and approved service operation satisfy the label policy. Administrative roles are separate from data-owner roles.

RBAC is used inside the MAC boundary for operational permissions: `VaultClient` may create, retrieve, and delete its own files; `VaultAuditor` may review approved audit records; `VaultOperator` may operate services; and `SysAdmin` may patch, configure, and restart hosts. No operational role grants plaintext file access.

### Admin Restriction

Client files are encrypted on the client side using envelope encryption before upload. A per-file data-encryption key is generated for the file and wrapped to a client-controlled public key. The ApexVault server stores only encrypted file contents and encrypted key material.

The client private key is held in the client’s approved hardware-backed keystore or HSM and is never stored on the ApexVault host. Decryption occurs only after the client authenticates and the client device unwraps the file key. The server may perform authenticated ciphertext storage and retrieval, but it has no decryption endpoint and never receives plaintext keys.

The server-side HSM protects service signing keys, token-verification keys, and key-wrapping policy metadata; it is configured not to release client decryption keys to administrators. Separate HSM authorization, dual control, and quorum approval are required for any key-management operation. SELinux enforcing mode, separate service accounts, MAC labels, disabled host-level debugging of the vault process, and audited break-glass procedures provide defense in depth. Consequently, `root` or `SysAdmin` can manage the host and service but cannot read client files in plaintext.

Authorization is deny-by-default. Every request is checked for tenant, object label, client identity, operation, session freshness, and device posture. Administrative access is performed through separate operator accounts; direct shared-root login is disabled.

## 3. Accounting Architecture

### Storage Location

The ApexVault host emits security and administrative events to a separate, centrally managed SIEM and immutable log archive over mutually authenticated TLS. Events include authentication attempts, FIDO2 enrollment and removal, authorization decisions, file metadata operations, key-management actions, policy changes, administrator sessions, break-glass use, and log-delivery failures.

The central logging account, network path, and storage credentials are separate from the ApexVault production account. The local host keeps only a short-lived operational buffer; it is not the system of record. The archive uses write-once, read-many (WORM) object storage with Object Lock/compliance retention, versioning, restricted deletion, and a retention policy approved by the CISO. Log collectors run under a separate identity and do not accept delete or overwrite commands from ApexVault hosts.

### Integrity Mechanism

Each event is serialized in a canonical format and includes a unique event ID, source, actor, timestamp, action, result, and previous-event hash. The collector builds per-source hash chains and periodically signs checkpoints with a dedicated signing key held in an HSM. The SIEM and archive verify signatures, sequence continuity, timestamps, and duplicate event IDs on ingestion.

Archive objects are encrypted at rest, versioned, and locked against modification or deletion until their retention period expires. Deletion requires an independent compliance workflow with dual authorization and is not available to SysAdmin or ApexVault service identities. Cross-region replication protects against loss of a single logging site.

Monitoring alerts on missing sequence numbers, broken signatures, clock drift, collector silence, failed replication, unauthorized policy changes, and any attempted deletion. These controls ensure that a hacker who compromises an ApexVault server cannot silently modify or delete the authoritative audit trail, resolving the Bob issue from Task 2.

