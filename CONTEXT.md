# Water Seven

Water Seven describes one mixed-ownership workstation fleet and the authorities that make its configuration, credentials, and recovery reproducible across macOS and NixOS.

## Language

**Host role**:
The primary usage context that supplies a workstation's default applications and configuration. It is neither the device owner nor a credential-security boundary.
_Avoid_: Device owner, credential authority

**Personal role**:
A host role for personal activity and personally selected application defaults.
_Avoid_: Private role

**Work role**:
A host role for company activity whose software and credential handling remain subject to company policy.
_Avoid_: Company ownership, credential authority

**Device owner**:
The person or organization with authority over a physical workstation's firmware, operating system, disk recovery, and lifecycle. Ownership constrains configuration even when the device is not centrally managed.
_Avoid_: Host role, MDM status

**Credential authority**:
The system or owner that issues, validates, and revokes a credential; copying a value into local storage does not transfer its authority.
_Avoid_: Secret store, source, vault

**Revocation domain**:
The set of credentials and access paths that must be reviewed together after one loss, compromise, or ownership change. It follows credential purpose and authority rather than workstation role.
_Avoid_: Personal/work boundary, host boundary

**Declarative secret**:
A selected static value whose encrypted representation and delivery requirements are versioned with Water Seven while plaintext remains outside evaluation and builds.
_Avoid_: Every secret, vault entry

**Runtime credential**:
Short-lived access material created for a process or login session and renewed from its authority rather than restored from configuration.
_Avoid_: Declarative secret, backup secret

**Local credential broker**:
The platform facility that protects and releases application credentials during an unlocked session, such as macOS Keychain or a Linux Secret Service implementation. It is a delivery adapter, not the credential authority.
_Avoid_: Vault, authority

**Recovery credential**:
An independently protected credential used only when the normal hardware-backed or interactive path is unavailable.
_Avoid_: Backup password, fallback copy

**Recovery kit**:
The offline, separately stored material and inventory needed to recover a blank machine without relying on another configured Water Seven host or one available cloud account.
_Avoid_: Backup key
