# Credential and secret security architecture

## Question

How should Water Seven place and operate personal and work credentials across macOS and NixOS when the environment includes a YubiKey 5 NFC (USB-C), separate personal and work Bitwarden accounts, STACKIT Secrets Manager, SOPS, platform credential stores, generated CLI credentials, disk encryption, and one GitHub account that spans both contexts?

## Recommendation

Use a **federated authority model**, not one universal vault. Classify every credential by who can issue or revoke it, how it reaches a process, and which incident requires it to be rotated. A host role is a useful default but is not a security boundary: the shared GitHub account proves that personal and work credentials can meet at one relying party while retaining different issuers and revocation procedures.

The recommended blank-machine recovery path is:

1. Buy a second YubiKey 5C NFC and provision it as an independently enrolled backup, not a clone.
2. Keep the backup key away from the daily key.
3. Maintain a sealed offline personal recovery kit containing password-manager recovery material, disk recovery credentials, a SOPS break-glass identity, and the personal credential-registration inventory. Encrypt its digital payload with a unique generated multiword passphrase and keep two sealed paper copies away from both the media and backup YubiKey.
4. Make personal Bitwarden available as the convenient online recovery source, but do not make it the only route.
5. Defer all Water Seven YubiKey integration while only one key exists. Provision or enforce hardware-backed paths only after the backup key is available and every fallback can be tested.

This avoids three single points of failure: one physical key, an already working workstation, and availability of one cloud account.

## Authorities and placement

| Material | Authority | Normal local placement | Recovery or renewal |
|---|---|---|---|
| Personal human credentials and recovery codes | Personal Bitwarden account or the issuing provider | Bitwarden client; copy to a process only when required | Personal Bitwarden plus selected sealed offline recovery material |
| Work human credentials and recovery codes | Company identity and credential policy | Company-approved storage such as the work Bitwarden account | Company recovery and offboarding policy |
| Work application/team secrets | Company policy and the issuing system | Company-approved facilities such as STACKIT Secrets Manager | Company-defined recovery, renewal, and versioning |
| Selected static personal machine secrets | SOPS file in this public repository | `sops-nix` protected runtime file | Host recipient, either operator YubiKey recipient, or offline break-glass recipient |
| OAuth, browser-login, and generated CLI sessions | Issuing service | macOS Keychain, Linux Secret Service, application-owned protected state, or process environment | Reauthenticate; do not back up access/session tokens as declarative secrets |
| Linux disk unlock | Each LUKS2 volume | LUKS2 token/keyslot | Two separately enrolled YubiKeys plus a unique recovery passphrase |
| macOS disk unlock | FileVault/Secure Enclave | Native FileVault state | Unique personal recovery key and account password |
| SSH authentication | Each remote relying party | Dedicated FIDO2 credential on each YubiKey; public key and local handle are non-secret metadata | Register both keys; remove a lost key at every relying party |
| Git commit/tag signing | GitHub and local Git trust configuration | Dedicated FIDO2 SSH signing credential, distinct from SSH authentication | Register both signing keys; revoke independently |
| Git author identity | The personal or work identity owner | Private Git include selected by host/repository context | Restore from the corresponding Bitwarden account or recreate interactively |

A secret copied into Keychain, Secret Service, or a runtime file does not change authority. Those mechanisms are delivery or local caching adapters, not backup systems.

## Personal and work overlap

Bitwarden clients support multiple logged-in accounts, and the CLI supports separate simultaneous states through `BITWARDENCLI_APPDATA_DIR`.[^bitwarden-switching][^bitwarden-cli] Water Seven may expose explicitly named personal and work CLI entry points when that improves the real workflow. `BW_SESSION` is a decryption session key; it belongs only in the invoking process environment and must be invalidated with `bw lock` or `bw logout` after use.[^bitwarden-cli]

Do not add a machine-wide personal/work context switch. Context has different native scopes: a browser profile can own web sessions, a project directory can select direnv or mise state, a repository can select Git identity, and a CLI can isolate its own configuration directory. Synchronizing these through one mutable ambient setting would be misleading for already-running and concurrent processes. Add an application-specific launcher or wrapper only where concrete use shows it is useful.

One GitHub account may contain personal and work email addresses, passkeys, SSH authentication keys, and signing keys. That does not make them one credential. Label and register separate purpose/domain keys, choose Git identity by repository location or remote context, and revoke only the affected key when possible. If company policy requires a company-owned authenticator or signing identity, add a work-dedicated device rather than changing ownership of the personal recovery keys.

No work secret or work-secret ciphertext belongs in Water Seven's public repository unless an explicit company policy later authorizes that exact publication model. Shared account names, encrypted field names, recipient metadata, and change timing can all reveal information even when SOPS protects values.

## YubiKey application plan

The YubiKey is a hardware holder for several independent credentials, not the authority for every secret.

### FIDO2

Use FIDO2 for:

- passkeys or second-factor credentials at Bitwarden, GitHub, and company services where policy permits;
- dedicated OpenSSH credentials for SSH authentication and Git signing;
- separately scoped `pam_u2f` credentials for NixOS login and sudo; and
- per-volume LUKS2 enrollment through systemd.

FIDO user presence is a physical touch; user verification can be a YubiKey PIN. OpenSSH's `verify-required` option enforces verification in addition to touch.[^yubico-ssh] `pam_u2f` exposes separate `pinverification` and `userpresence` requirements.[^pam-u2f] `systemd-cryptenroll` likewise has distinct client-PIN and user-presence controls, both defaulting to enabled for FIDO2 enrollment.[^systemd-cryptenroll]

Use **PIN plus touch** for every privileged workstation operation. Do not reuse one FIDO credential for SSH authentication, Git signing, login, and sudo merely because one physical token can hold all of them. The FIDO2 PIN is shared by credentials on one token, but server-side credentials and revocation remain distinct.

Before choosing an OpenSSH algorithm, record the installed firmware with `ykman info`. `ed25519-sk` resident credentials require YubiKey firmware 5.2.3 or newer; `ecdsa-sk` is the compatibility fallback. A resident credential can be recovered from the token with `ssh-keygen -K`, while the downloaded handle still contains no extractable private key.[^yubico-ssh]

### PIV

Reserve a retired PIV slot for an `age-plugin-yubikey` operator identity. The plugin stores the private key on the token and keeps only a reconstructible identity descriptor on disk; it supports YubiKey 5 devices and uses retired PIV slots rather than the standard authentication slots.[^age-plugin-yubikey] Configure PIN-once and touch-always for practical SOPS editing: a removal or applet switch clears the PIN session, while each private-key operation still requires presence.

The plugin changes global PIV administration when defaults are still present: it changes the default PIN/PUK state and replaces the default management key with protected metadata.[^age-plugin-yubikey] Provision and test this before introducing any other PIV use.

Do not initially use PIV for macOS login. Apple supports PIV-compatible smart-card login and Apple-silicon FileVault authentication, but this couples login, FileVault, certificates, token pairing, and recoveryOS procedures.[^apple-smartcard][^apple-filevault-smartcard] `baratie` already has platform hardware-backed protection through the Secure Enclave and Touch ID. Keep FileVault password/recovery-key unlock and Touch ID sudo with password fallback. Reconsider macOS smart-card login only after two YubiKeys exist and a disposable Apple-silicon VM or spare Mac has exercised enrollment, reboot, loss, and unlink recovery.

Disable unused YubiKey applications only after inventorying current use. The intended baseline is FIDO2 over USB/NFC and PIV over USB; OTP, OATH, and OpenPGP remain off unless a concrete credential requires them.

## Disk encryption

### NixOS

Each physical LUKS2 volume keeps three independent classes of unlock path:

1. daily primary YubiKey enrollment with client PIN and touch;
2. separately enrolled backup YubiKey; and
3. a unique high-entropy recovery passphrase.

Systemd stores FIDO2 enrollment metadata in the LUKS2 JSON token area and uses the token's `hmac-secret` extension to acquire the unlock key.[^systemd-cryptenroll] The recovery passphrase must not equal the Unix login password or another host's disk secret. Store it in personal Bitwarden and in the sealed recovery kit.

The selected interim target for `striker` is transparent TPM2-assisted unlock: an authorized signed boot chain may release the LUKS key without user input, after which the OS login is the user-authentication boundary. This is stronger than an unencrypted disk against SSD removal and unauthorized measured boot paths, but deliberately weaker than requiring a user-held secret before mounting.

Do not enroll the TPM until a dedicated design validates Secure Boot, signed unified kernel images, PCR policy across NixOS generations and rollback, firmware/kernel updates, suspend behavior, TPM clearing or motherboard replacement, and clean fallback to the independent recovery passphrase. Reconsider the transparent path when YubiKey integration resumes, because it otherwise bypasses any requirement for token presence during disk decryption.

VM disks keep independent passphrases. USB token passthrough is too fragile to be their only unlock path. Any VM receiving a real secret has credential-bearing snapshots and exports.

### macOS

Keep native FileVault ownership. Apple-silicon FileVault uses the Secure Enclave and requires a user credential at boot; a personal recovery key is the independent recovery mechanism.[^apple-filevault] Preserve that key in personal Bitwarden and the offline recovery kit. Water Seven may verify FileVault state but must not print, log, or import its recovery key through Nix evaluation.

## SOPS as declarative delivery

Actual SOPS payloads and `sops-nix` activation are deferred until the second YubiKey is available. Keep the pinned input and architecture, but do not introduce an interim software operator identity merely to deploy SOPS early. Revisit only for a concrete unattended personal secret whose complete recipient and recovery model justifies the exception.

SOPS is for selected **static, machine-consumed, personal-scope values** whose ciphertext and metadata are acceptable in a public repository. It is not the password manager, work vault, session cache, or universal backup format. SOPS supports age recipients and encrypted structured files.[^sops] `sops-nix` decrypts system secrets into non-persistent runtime locations and supports NixOS, nix-darwin, and Home Manager adapters.[^sops-nix]

Use three recipient classes:

- a unique generated age identity for each authorized host, protected at rest by that host's disk encryption;
- independent age-plugin recipients on the primary and backup YubiKeys for normal operator editing/rekeying; and
- one offline software age identity for break-glass recovery.

The host identity allows unattended activation without requiring a YubiKey. It is replaceable rather than backed up: after reinstalling a host, use an operator or recovery identity to add the new host recipient and remove the old one. The operator keys allow editing without copying an extractable private identity onto every workstation. Multiple recipients provide alternatives, not a threshold scheme.

Decrypted material must be a least-privilege runtime file whenever possible. Create a process-local environment variable only for software that cannot consume a file. Evaluation, builds, and CI must not require plaintext. Never place plaintext in a derivation, store path, command argument, log, shell trace, or clipboard.

Good initial SOPS candidates include host-scoped Wi-Fi or static application configuration when the metadata is safe to publish. Bad candidates include `BW_SESSION`, OAuth access/refresh state, GitHub CLI browser sessions, FileVault/LUKS recovery material, YubiKey PINs, and all work secrets.

## Remote and local secret stores

STACKIT describes Secrets Manager as a managed secure key-value store with an API and per-secret version history.[^stackit] Those product capabilities do not give Water Seven authority over its use. Company policy decides which secrets live there and prescribes authentication, retrieval, caching, rotation, and recovery. Water Seven may package a client or support a concrete approved workflow, but it must not invent a general STACKIT integration or make `darwin-rebuild` depend on work credentials, SSO, or network availability. Do not assume HashiCorp Vault/OpenBao protocols, dynamic leases, transit encryption, or a particular authentication flow unless company documentation requires them.

On macOS, use Keychain for applications that support it. Apple protects keychain data with access controls tied to the user/device security model.[^apple-keychain] On Linux, use GNOME Keyring as the Secret Service implementation for applications that support the freedesktop interface.[^secret-service][^gnome-keyring-pam] Keep its role narrow: install no GNOME desktop or applications, and do not let it replace the OpenSSH or future hardware-key agent design. A FIDO-only desktop login cannot automatically supply a symmetric login-keyring password; accept a first-use keyring unlock prompt rather than storing that password to bypass the prompt. Water Seven manages broker availability and non-secret integration, not stored contents or interactive access decisions.

When an application supports neither local broker, a mode-`0600` application-owned file on the encrypted volume is acceptable. It remains mutable credential state, not declarative configuration. Reauthentication is the default recovery path for Codex, Claude, GitHub CLI, AWS SSO, Linearis, and similar tools; do not extract their live access, refresh, cookie, or session state into SOPS or a password vault. Classify genuinely long-lived personal API keys individually. If valuable non-secret history shares an authentication directory, treat preserving it as a separate application-data backup decision rather than copying the whole directory for convenience.

## Git identity and signing

Use SSH-format Git signatures because GitHub supports SSH signing and it avoids introducing OpenPGP solely for Git.[^github-signing] Create a dedicated FIDO2 resident signing credential with `verify-required`; do not reuse the SSH authentication credential. Register the primary and backup signing public keys separately with GitHub. The active private handle and public key are local metadata; the private key remains on the YubiKey.

Keep author name/email out of the public Nix configuration. Restore private personal and work identity files from their corresponding approved authority or create them interactively. A private context map selects them through directory-specific `includeIf "gitdir:..."` rules; host role supplies no identity default. Set `user.useConfigOnly = true` so repositories outside a classified tree fail to commit rather than accepting a guessed identity. Exceptional repositories use an explicit repository-local include.

Git evaluates `gitdir:` against repository metadata. Standard linked worktrees placed in a flat directory retain metadata below the main repository's `.git/worktrees` directory and therefore normally retain its classification. Test the actual `work` CLI layout: an independent flat clone needs another explicit condition, while a standard linked worktree should not.

## Recovery, rotation, and revocation

Maintain a private credential registry with, for each hardware credential: token nickname and serial, application/purpose, relying party, public-key fingerprint or credential label, creation date, recovery path, and revocation URL/procedure. Partition it by authority: keep personal entries in personal Bitwarden with an offline copy, and work entries only in work Bitwarden or another company-approved system. Publish neither YubiKey serials nor work relying-party details in this repository.

YubiKey-dependent implementation is deferred until the second key is available. Then provision in this order:

1. Inventory both YubiKeys' firmware and existing applications without resetting anything.
2. Acquire the backup YubiKey.
3. Set non-default FIDO2 and PIV administration credentials and record break-glass material offline.
4. Create distinct credentials on both keys and register both with every relying party.
5. Create primary, backup, and offline SOPS recipients; prove each against a fixture.
6. Add both keys and a recovery passphrase to LUKS2; boot-test each path.
7. Test Bitwarden and repository recovery from a clean browser/live image.
8. Only then make hardware-backed login or sudo the normal path.

For a lost key, use the backup key or disk recovery secret, then remove every credential listed for the lost token, remove its SOPS recipient, provision a replacement, and test before returning to an enforced policy. For a compromised host, revoke local sessions and generated application tokens, rotate every static secret the host could decrypt, remove its SOPS recipient, and generate a new host identity after reinstall. Rotate hardware credentials on loss, suspected compromise, ownership change, or policy demand—not merely on an arbitrary calendar.

## Implementation sequence

1. Add platform credential-store support and introduce account-specific wrappers only for demonstrated workflows.
2. Research and validate Secure Boot, signed UKIs, PCR policy, updates, rollback, and recovery before enrolling transparent TPM2 unlock on `striker`.
3. Acquire the backup YubiKey and prepare the offline recovery kit before any YubiKey integration.
4. Inventory and provision both keys together.
5. Introduce SOPS with a non-sensitive fixture, host recipients, both YubiKey recipients, and the offline recipient.
6. Provision dedicated SSH authentication and Git signing credentials, then enable private Git identity/signing configuration.
7. Enroll and test both YubiKeys for `striker` LUKS2.
8. Add one NixOS local-authentication credential per host/key for login and sudo; enforce only after console and recovery tests.
9. Leave macOS PIV login deferred unless its additional value justifies the recovery complexity.

## Sources

[^bitwarden-switching]: [Bitwarden: Log in to multiple accounts](https://bitwarden.com/help/account-switching/)
[^bitwarden-cli]: [Bitwarden Password Manager CLI](https://bitwarden.com/help/cli/)
[^yubico-ssh]: [Yubico: Securing SSH with FIDO2](https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html)
[^pam-u2f]: [Yubico `pam_u2f` manual](https://developers.yubico.com/pam-u2f/Manuals/pam_u2f.8.html)
[^systemd-cryptenroll]: [`systemd-cryptenroll`](https://www.freedesktop.org/software/systemd/man/latest/systemd-cryptenroll.html)
[^age-plugin-yubikey]: [`age-plugin-yubikey` upstream documentation](https://github.com/str4d/age-plugin-yubikey)
[^apple-smartcard]: [Apple Platform Deployment: Use a smart card on Mac](https://support.apple.com/guide/deployment/use-a-smart-card-on-mac-depc705651a9/web)
[^apple-filevault-smartcard]: [Apple Platform Deployment: FileVault and smart card usage](https://support.apple.com/guide/deployment/filevault-and-smart-card-usage-dep806850525/web)
[^apple-filevault]: [Apple Platform Deployment: Intro to FileVault](https://support.apple.com/guide/deployment/intro-to-filevault-dep82064ec40/web)
[^sops]: [SOPS documentation](https://getsops.io/docs/)
[^sops-nix]: [`sops-nix` documentation and platform modules](https://github.com/Mic92/sops-nix/tree/a8627b21b9107c5711c96b84f32a9a4b3d45295f)
[^stackit]: [STACKIT Secrets Manager product documentation](https://stackit.com/en/products/security/stackit-secrets-manager)
[^apple-keychain]: [Apple Platform Security: Keychain data protection](https://support.apple.com/guide/security/keychain-data-protection-secb0694df1a/web)
[^secret-service]: [freedesktop.org Secret Service specification](https://specifications.freedesktop.org/secret-service/latest/)
[^gnome-keyring-pam]: [GNOME Keyring PAM integration](https://gitlab.gnome.org/GNOME/gnome-keyring/-/blob/master/pam/README)
[^github-signing]: [GitHub: About commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)
