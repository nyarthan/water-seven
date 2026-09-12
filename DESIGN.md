# Water Seven: Grilled Design

> Status: sufficiently specified to begin implementation. This document consolidates the design grilling session. Decisions marked deferred are intentionally outside the initial implementation unless they become necessary.

## Implementation mandate

Build toward the complete design rather than presenting a sequence of user-facing slices or stopping after intermediate milestones. Work may still be ordered internally, and every coherent change must be verified, but intermediate slices are not the deliverable.

The first machine brought up will be the disposable NixOS VM `mini-merry`. Continue from there until the macOS and physical NixOS notebook configurations, native iteration model, bootstrap paths, validation, and rollback described here work.

## Vision

Create a personal, public system configuration with:

1. As much declarative setup as each platform reliably permits.
2. A unified user experience across macOS and Linux.
3. Fast feedback when editing frequently changed configuration.
4. Explicit, reproducible deployment and recovery.

The initial fleet is:

| Host | Platform | Role |
|---|---|---|
| `mini-merry` | `aarch64-linux` NixOS VM hosted on the Mac | Complete test workstation; `egghead` role |
| `mini-sunny` | `aarch64-darwin` macOS VM hosted on the Mac | Disposable Darwin test workstation; `egghead` role |
| `baratie` | `aarch64-darwin` MacBook | Work-oriented workstation |
| `striker` | `x86_64-linux` NixOS notebook | Private-oriented workstation |

The Mac currently reports another hostname (`ghost`), but its declared identity going forward is `baratie`.

Future VMs, desktops, and servers may be added when they have concrete roles. Do not generalize for them now.

## Project identity

The new public project is **Water Seven**, with repository name `water-seven`.

Its required checkout is:

```text
$XDG_PROJECTS_DIR/water-seven
```

Declare `XDG_PROJECTS_DIR` consistently on both platforms, defaulting to:

```text
~/Projects
```

This uses the Projects user directory enabled by `xdg-user-dirs` 0.20. On macOS the project establishes the same convention explicitly.

Tendril is deprecated. It has no compatibility status and no specified coexistence or migration protocol. Consult it only when an existing behavior or implementation is demonstrably useful; do not copy its structure or contents blindly.

## Scope

### Managed desired state

- NixOS and nix-darwin system configuration
- Users, groups, shells, privileges, and host identity
- Home Manager configuration integrated with system generations
- Packages and custom package definitions
- Native application configuration
- Cross-platform interaction behavior
- Platform-specific desktop behavior
- Disk layout and NixOS installation
- Guided macOS convergence
- Encrypted secret requirements and deployment
- Validation, activation, rollback, and recovery

### State outside the system's responsibility

- Personal working files and application databases
- Ensuring unfinished source code is pushed to a remote
- Current windows and workspace contents
- tmux processes across reboot, initially
- Browser history and mutable browser profiles, initially
- Application account databases
- Apple ID, password, biometric, MFA, and hardware-key entry

The system may install, seed, or guide applications that own such state without trying to reproduce their databases.

### Personal infrastructure

Water Seven is personal infrastructure, not a framework for arbitrary users. Add abstractions where two supported implementations genuinely vary. Avoid interfaces for hypothetical consumers.

## Configuration architecture

### Nix structure

Use a **dendritic** flake architecture.

- Stable nixpkgs is the default package universe.
- Home Manager is integrated into NixOS and nix-darwin generations.
- One flake revision pins all hosts.
- Profiles compose statically at evaluation time.
- The initial supported systems are `aarch64-darwin`, `aarch64-linux`, and `x86_64-linux`.
- Individual features may explicitly and locally select a package from nixpkgs-unstable when stable is inadequate.
- Do not expose a general unstable package namespace throughout the configuration.
- Allow unfree packages through an explicit allowlist.

Expected profile composition:

```text
shared workstation
    └── role: work, private, or VM test role
          └── platform: macOS or NixOS
                └── host: hardware facts and exceptions
```

The work/private distinction is mostly accounts, credentials, applications, and other role-specific configuration. Shell, editor, terminal, and interaction behavior remain shared.

### Declarative management tiers

Classify application and system settings as:

1. **Enforced** — reliably converged on activation.
2. **Seeded** — initialized automatically, then allowed to mutate.
3. **Documented** — unavoidable manual work with a guided/checkable instruction.

Use Nix wherever it models the desired state well. Convergent scripts or native tools wrapped by Nix are acceptable where the platform has no suitable Nix interface.

## Configuration authority

Every setting has one authority. Several files or adapters may implement one decision, but two independently editable sources must not own the same setting.

Configuration belongs to one of four categories:

1. **Native source** — handwritten files in an application's native format.
2. **UX contract** — shared behavior that requires translation between platforms.
3. **Generated facts** — read-only package paths, host facts, and derived values.
4. **Platform extras** — native behavior with no cross-platform counterpart.

Duplicate adapter implementation is sometimes unavoidable. Duplicate authority is not. Agents may help maintain adapters, but automated checks—not agent diligence—must detect missing or inconsistent implementations.

### Native/generated composition

Prefer native configuration for iterable applications. Where supported, handwritten native files import generated fragments. Generated fragments are build artifacts: they are read-only, uncommitted, and own only their declared settings.

An adapter may use whichever composition mechanism its target supports:

1. Native import/include of a generated fragment
2. Nix composition of independently owned fragments
3. Entire-file generation when the target provides no composition mechanism

Evaluate each configuration system individually. Do not impose one mechanism on every target.

## Native iteration

### Model

There is one authoritative native file in the Water Seven checkout. Selected applications read it directly. There is no edit mode and no activation command before editing.

Accepted consequences:

- Saving a native file can affect an application immediately.
- Uncommitted edits remain active across login and restart.
- Git displays, preserves, and reverts experiments.
- A commit makes native changes portable and recoverable through the repository.
- A rebuild validates the clean revision and updates packages, generated fragments, and other Nix-managed state.
- The checkout is required workstation infrastructure.
- There is no separately maintained runtime or frozen fallback copy.
- Nix store snapshots created during evaluation or testing are disposable artifacts, not configuration authorities.

The earlier idea of automatically reverting native changes at login was rejected because preserving edits while deactivating them requires hidden session tracking, duplicate checkouts, or explicit mode transitions.

### Initial iterable applications

1. Hyprland/Aerospace window-manager configuration where native composition permits
2. Neovim
3. tmux
4. Fuzzel/Raycast launcher configuration where practical
5. Ghostty
6. Bash

Respect each application's native reload behavior. Do not add a universal watcher or reload supervisor without evidence that it improves a real workflow.

## UX contract

The UX contract is a thin, platform-independent declaration of **available actions and muscle-memory bindings**. It does not attempt to make macOS and Linux use the same layout algorithm or define every adapter detail.

Represent the executable contract in Nix. Platform adapters translate it into native configuration.

### Support levels

- **Required** — adapter support is mandatory; evaluation fails when absent.
- **Preferred** — degradation is visible or documented.
- **Platform-native** — deliberately outside shared behavior.

### Input contexts

Native application conventions remain native. For example, copy is Command-C on macOS and Control-C on Linux.

Custom shortcuts use contextual physical layers:

| Context | Linux | macOS | Purpose |
|---|---|---|---|
| Desktop | Super | Option | Window and workspace management |
| Terminal | Alt | Command | tmux navigation |
| Editor | Control | Control | Neovim behavior |

The physical gesture and action matter more than the printed modifier name. A single physical keyboard is normally shared between machines.

Device-specific keyboard normalization is deferred. When introduced, normalize hardware before applications receive input instead of spreading device exceptions across application configuration.

### Initial desktop actions

The initial contract exposes bindings for:

- Focus window left/down/up/right
- Move window left/down/up/right
- Select workspace 1 through 9
- Move the current window to workspace 1 through 9
- Toggle floating
- Toggle maximize
- Open the launcher
- Open a terminal
- Close the focused window
- Lock the session
- Log out of the session

Starting binding shape:

- Desktop-H/J/K/L: directional focus
- Desktop-Shift-H/J/K/L: directional movement
- Desktop-1…9: workspace selection
- Desktop-Shift-1…9: move window to workspace
- Desktop-F: floating toggle
- Desktop-Shift-F: maximize toggle
- Desktop-Space: launcher
- Desktop-Return: terminal
- Desktop-Q: close focused window
- Desktop-Escape: lock session
- Desktop-Shift-Escape: log out

True/native fullscreen is distinct from maximize and remains a separate platform-native action initially.

### Adapter-owned behavior

The shared contract intentionally does not define:

- Tiling versus scrolling layout
- Exact insertion algorithm
- Exact meaning of directional reordering
- Container-tree manipulation
- Floating-window geometry restoration
- Detailed cross-monitor transitions
- Launcher search features beyond its existence and shortcut
- Application switching
- Workspace indicators

A good Linux layout need not be degraded to match macOS.

### Workspaces

- Workspace identifiers are globally meaningful.
- Provide nine directly bound numeric slots initially.
- Empty inactive workspaces may be hidden from native indicators.
- Workspaces are ephemeral task/intent contexts populated manually.
- Examples include music running in the background, the current work item, or side research.
- Do not assign applications automatically by type.
- Runtime contents and current selection remain local session state.
- An intent normally occupies one monitor-sized workspace.
- With two monitors, different intents will usually be visible on each.
- Synchronized multi-monitor workspace groups are unnecessary initially.
- Monitor switching details remain adapter policy.
- Keyboard focus is authoritative; pointer movement does not steal focus.

Hyprland's native model is compatible enough: workspace IDs are global, each workspace belongs to one monitor at a time, and each monitor displays an active workspace.

## Desktop adapters

### Linux

Use Hyprland as a replaceable adapter behind the UX contract. The contract does not expose Hyprland-specific tree or layout concepts.

The Hyprland module owns a complete usable desktop substrate:

- Hyprland session startup
- Fuzzel launcher
- Minimal Waybar for time, battery, network, audio, and native status
- Screen locking and idle handling
- Desktop portals and screen sharing
- Polkit authentication
- Audio
- Network management
- Brightness and media keys
- Clipboard utilities
- Screenshots
- Wallpaper
- Laptop lid and suspend behavior

Notifications are omitted initially. Add them when they become useful.

Monitor behavior:

- Declare layouts for known monitors.
- Provide a usable fallback for unknown monitors.
- Permit runtime adjustment for temporary displays.
- Promote recurring layouts into configuration later.

Hardware keys for volume, mute, brightness, keyboard backlight, media, and suspend are required for an initially usable Linux session but remain platform-native behavior.

### macOS

Use Aerospace for window management and Raycast for launching. Translate the shared UX bindings through their adapters. Detailed movement, workspace-monitor behavior, and native macOS limitations remain adapter-owned.

macOS default applications and file associations are reconverged best-effort on explicit activation.

## Terminal stack

### Ghostty

Ghostty is the shared terminal.

- One shared handwritten native core owns font, theme, padding, cursor, and general behavior.
- Small platform fragments own genuine rendering/window-system differences.
- A generated fragment owns Nix-derived values and translated bindings.
- Use Ghostty's native `config-file` composition.
- Validate with `ghostty +validate-config`.
- Respect Ghostty's native reload support.

Ghostty owns OS windows and terminal rendering. tmux exclusively owns terminal panes, windows, and persistent sessions. Ghostty tabs and splits are unused or unbound.

### tmux

- Every ordinary Ghostty terminal automatically enters a local tmux session named `main`.
- Use Bash's native `--noprofile --norc` flags when a clean diagnostic shell is needed.
- Closing Ghostty leaves the tmux session alive.
- Session resurrection across reboot is deferred but likely desirable later.
- Retain the default Control-B prefix for uncommon actions.
- Initial direct actions are terminal-layer H/J/K/L for pane focus and terminal-layer 1…9 for tmux-window selection.
- Pane/window movement bindings are deferred until their semantics are useful.
- Linux sends Alt bindings normally; Ghostty translates the equivalent macOS Command-layer chords.

### Bash

Use a modern Nix-managed Bash as the login and interactive shell on every host. Do not support macOS Bash 3.2 as an interactive compatibility target.

- Handwritten Bash configuration lives in the checkout and is read directly.
- Generated fragments provide Nix-managed paths and environment facts.
- Reload by starting a new shell or explicitly sourcing configuration.

Shared shell conveniences initially include:

- Starship
- zoxide
- fzf
- direnv
- Atuin with local-only history
- Bash completion
- A modern pager
- Common interactive CLI tools

Shell history uses the same tool/configuration but does not synchronize between machines initially.

Mise is installed and activated as a compatibility mechanism for projects that declare it. Its Home Manager-owned global tool table is intentionally empty. Prefer Nix development shells in projects under personal control. One project owns its toolchain; do not combine Nix and mise ownership for the same tools.

Direnv activation requires `direnv allow` once per checkout. After trust is granted, entering a supported project activates its declared environment automatically. Projects without environment declarations are left alone.

## Neovim

- Use stable Neovim from the stable package universe.
- Nix owns Neovim installation, plugin installation, selected Tree-sitter parsers, and commonly used editor tools.
- Lua owns plugin loading, configuration, editor behavior, and all Control-layer keybindings.
- Treat Tree-sitter parsers like plugins.
- Provide commonly used language servers and formatters with the Neovim package.
- Native Neovim configuration detects/selects tools at runtime.
- Do not require projects to contain Neovim-specific configuration.
- Project environments may still provide project-specific tools.

## Applications and visual baseline

Initial shared GUI baseline:

- Bitwarden desktop application and CLI
- Ghostty
- Brave as the default browser
- Platform window manager
- Platform launcher

Chrome is installed only by the private role.

Add communication, office, media, gaming, and other applications deliberately after the foundation exists. The current Mac's installed application list is evidence, not desired state.

Use dark appearance where supported. Keep native OS widget themes platform-specific.

Use Iosevka as the shared terminal/editor monospace font. Native system UI fonts remain platform defaults.

File managers, screenshots, and clipboard behavior remain platform-native initially. Browser profiles, groups/containers, history, and application accounts remain application-owned mutable state. Declarative browser profile/container management may be investigated later. On macOS, changing the effective default browser requires interactive user approval: Water Seven installs Brave, guides that consent, and verifies the live LaunchServices handler rather than writing an ineffective `LSHandlers` preference.

## Package acquisition

Use the first viable source in this order:

1. Stable nixpkgs package
2. Explicit nixpkgs-unstable exception when stable is inadequate
3. Declaratively managed Homebrew cask
4. Declaratively requested App Store application
5. Documented vendor/manual installation

Stable and explicitly justified unstable packages are both the preferred
nixpkgs tier. Do not select Homebrew merely because an application is commonly
installed as a cask. Project-owned package expressions are exceptional and
require a documented reason not to use the normal source order.

On macOS:

- `nix-homebrew` installs and pins Homebrew itself; nix-darwin manages the declared formulae, taps, and casks.
- Explicit activation removes unlisted Homebrew packages using uninstall cleanup, not destructive zap cleanup.
- Gatekeeper quarantine may be disabled per declaratively trusted cask, but never globally for arbitrary downloads.
- Disable application self-update where practical.
- Where self-update cannot be controlled, declare application presence and classify version convergence as best-effort.
- App Store authentication is a guided manual gate.
- Exact Homebrew/App Store application versions may not be reproducible.

The UX contract does not depend on package source.

## Accounts and host security

Use the fixed Unix username `jannis` on both notebooks. The macOS account is created manually during Setup Assistant and verified by bootstrap; NixOS creates it declaratively.

Declare account existence, groups, shell, home, and privileges. Passwords and disk-unlock credentials remain bootstrap secrets and are independent per machine.

Shared notebook baseline:

- FileVault on macOS
- LUKS2 full-disk encryption on NixOS
- No automatic login
- Firewall enabled
- No inbound SSH after installation
- Root login locked on NixOS
- Remote root login disabled
- User receives wheel/sudo access
- Guest accounts disabled
- Screen locks after ten minutes idle
- Authentication required immediately after lock
- Touch ID for sudo on macOS, with password fallback

Inbound SSH is host-specific and may be introduced for future desktops or servers. It is disabled on the initial notebooks after bootstrap.

Secure Boot activation remains gated while it is deployed in observable stages with TPM2-assisted LUKS unlock. Follow [the `striker` Secure Boot and TPM design](docs/research/striker-secure-boot-tpm.md): Lanzaboote first, firmware enforcement second, measured policy third, and LUKS TPM enrollment last. Lanzaboote uses signed generation stubs with hash-verified kernel, initrd, and embedded command-line artifacts rather than requiring each artifact to be independently signed.

Erase-on-boot impermanence is deferred. First prove reliable recovery from a blank disk.

Tailscale is deferred until remote access or VM connectivity becomes a real workflow.

## Credential security

Water Seven uses separate credential authorities and revocation domains rather than one universal vault. Host roles provide defaults, but they are not security boundaries: a relying party such as GitHub may span personal and work contexts while its individual credentials retain distinct ownership and revocation.

The full rationale, platform findings, and rollout sequence are in [Credential and secret security architecture](docs/research/credential-security-architecture.md) and [ADR 0001](docs/adr/0001-separate-credential-authorities.md).

### Authorities

- Personal Bitwarden owns human-oriented personal credentials and selected recovery records.
- Company policy governs work credentials, approved storage, access, recovery, and offboarding. Work Bitwarden and STACKIT Secrets Manager are company-managed facilities, not authorities controlled by Water Seven.
- Issuing services own OAuth, browser-login, and generated CLI credentials; local copies are renewable application state.
- SOPS owns delivery of only selected static, machine-consumed, personal-scope secrets.
- FileVault and each LUKS2 volume own their independent disk credentials.
- macOS Keychain and a Linux Secret Service implementation are local credential brokers, not authorities or universal backups.

No work secret or work-secret ciphertext enters the public repository unless company policy later authorizes the exact publication model. Account overlap does not relax this rule.

Bitwarden desktop/browser clients may hold both accounts through native account switching. CLI use may keep separate personal and work state directories and process-local sessions where that improves the actual workflow. `BW_SESSION`, STACKIT access tokens, OAuth tokens, and equivalent session material are never declarative secrets.

Personal/work context selection remains application-owned. Browser profiles, project directories with direnv or mise, repository-local Git rules, named cloud profiles, and isolated CLI state solve different problems; do not synchronize them through a machine-wide current-context switch. Add context-specific launchers or wrappers only for applications with a demonstrated need, using that application's native scoping mechanism.

### YubiKey policy

The current hardware is one YubiKey 5 NFC with USB-C. All YubiKey integration is deferred until a second YubiKey 5C NFC is available as an independently enrolled backup. Until then, do not mutate the current key, register Water Seven credentials on it, enroll it for LUKS, or make configuration depend on its presence. The intended keys contain separate credentials; they are not clones.

Privileged YubiKey operations require PIN plus physical touch. Use purpose-specific credentials:

- FIDO2 web credentials for each relying party;
- separate FIDO2 OpenSSH credentials for SSH authentication and Git signing;
- separately scoped FIDO2 credentials for NixOS login and sudo;
- per-volume FIDO2 enrollment for LUKS2; and
- one retired PIV slot per key for a SOPS operator age identity.

Record firmware before selecting an OpenSSH key type. Prefer resident `ed25519-sk` credentials with `verify-required` on firmware 5.2.3 or newer; use `ecdsa-sk` as the compatibility fallback. Public keys and local key handles are metadata; private key material remains on the token.

Provision `age-plugin-yubikey` before any other PIV use because it changes default global PIV administration. Use PIN-once and touch-always for operator decryption. The primary YubiKey, backup YubiKey, and offline recovery identity are independent SOPS recipients.

Do not initially add YubiKey PIV login to macOS. `baratie` keeps FileVault password/recovery-key unlock and Secure Enclave/Touch ID sudo with password fallback. Reconsider smart-card login only after two keys exist and enrollment, reboot, loss, and unlink recovery have passed on disposable Apple-silicon hardware.

### Disk encryption

Every disk credential is unique and independent of the Unix login password.

`striker` will retain a high-entropy LUKS2 recovery passphrase and, after the hardware-key deferral ends, separately enroll both YubiKeys with client PIN and user presence. The recovery passphrase remains valid when neither token nor the TPM path is available.

Use transparent TPM2-assisted unlock for `striker` once its boot-integrity design has been validated. A recognized signed boot chain may unlock LUKS without user input; the OS login then becomes the user-authentication boundary. This deliberately accepts that the root filesystem is mounted at the login screen in exchange for protection against SSD removal and unauthorized measured boot paths without an extra normal-boot prompt.

Design and test TPM enrollment together with Lanzaboote's signed generation stubs and measured artifacts, PCR policy across NixOS generations and manual rollback, firmware/kernel updates, suspend behavior, TPM clearing or motherboard replacement, and the recovery-passphrase path. Start with PCR 4 for recognized boot artifacts and PCR 7 for Secure Boot state/authority. Defer PCR 0 firmware binding until a controlled firmware-update and policy-recovery rehearsal passes. Keep automatic boot counting disabled until a useful workstation boot-success criterion is designed and tested separately. Failed measurements must fall back cleanly to recovery. Retain the independent high-entropy LUKS recovery passphrase. When YubiKey integration resumes, reconsider transparent TPM unlock because leaving it enabled means YubiKey presence is not required for disk decryption.

VMs retain independent passphrases and never depend on USB passthrough for recovery. A VM that receives a real secret has credential-bearing snapshots and exports.

FileVault remains macOS-native. Preserve its personal recovery key in personal Bitwarden and the offline recovery kit; never expose it through Nix evaluation, output, or logs.

### Declarative delivery with SOPS

Actual SOPS payloads and `sops-nix` activation are deferred with YubiKey integration. Keep the pinned input and intended architecture, but do not create an interim software operator identity merely to deploy SOPS early. Revisit the deferral only if a concrete unattended personal secret creates an earlier need and its recipient/recovery model is reviewed explicitly.

SOPS ciphertext, filenames, recipients, and change metadata are public. Include only values for which that disclosure is acceptable.

Each authorized host receives a unique generated age identity protected by its encrypted disk. Each SOPS file may additionally grant the primary YubiKey, backup YubiKey, and offline break-glass identity. Host identities permit unattended activation and are replaceable on reinstall rather than backed up.

Rules:

- Plaintext never enters Git history, Nix store paths, logs, command arguments, shell traces, or the clipboard.
- Secret requirements, owners, permissions, and runtime paths are declared publicly.
- Missing required secrets fail activation early and clearly.
- `sops-nix` exposes least-privilege, non-persistent runtime files.
- Process-local environment variables are derived only when an application cannot consume a file.
- Evaluation, builds, and CI do not require decryption.
- Hardware-token decryption is for editing, rekeying, and recovery; routine host activation uses the host recipient.

Do not put password-manager sessions, OAuth state, GitHub CLI sessions, disk recovery credentials, YubiKey administration secrets, renewable Linearis tokens, or any work material in SOPS. `mini-merry` may decrypt only explicitly granted files through its host recipient; its snapshots and exported disks are then sensitive. Keep `mini-sunny` free of real credentials by default.

### Local and renewable credentials

Applications use Keychain on macOS and Secret Service on Linux when supported. GNOME Keyring is the selected NixOS Secret Service implementation despite the non-GNOME desktop because it provides the widely supported interface and PAM integration. Install only the keyring/Secret Service closure required for that role; do not add the GNOME desktop, GNOME applications, or GNOME Keyring's SSH/GPG-agent responsibilities.

Otherwise, a mode-`0600` application-owned file on the encrypted volume is acceptable. A FIDO-only Linux login cannot automatically provide a login-keyring password; prompt to unlock the keyring rather than storing that password to bypass the prompt. Water Seven owns broker availability and non-secret integration, never Keychain/keyring contents or interactive access decisions.

Browser-generated and OAuth CLI credentials remain application-owned mutable state. Reauthentication is the default recovery path for Codex, Claude, GitHub CLI, AWS SSO, Linearis, and similar tools; do not back up their live access, refresh, cookie, or session state through SOPS or a password vault. Classify genuinely long-lived personal API keys individually, and handle valuable non-secret history mixed into an authentication directory as a separate application-data backup decision. Water Seven does not decide which work secrets belong in STACKIT or how they are accessed; it may support a concrete company-approved workflow without making system rebuilds depend on work credentials, SSO, or network availability.

### Git identity and signing

Use SSH-format Git commit and tag signatures from a dedicated resident FIDO2 signing credential, distinct from SSH authentication. Register primary and backup signing keys independently.

Keep author name and email in private personal/work identity files restored from the corresponding approved authority or created interactively. A private Git context map selects them with directory-specific `includeIf "gitdir:..."` rules; host role supplies no identity default. Set `user.useConfigOnly = true` so an unclassified repository fails to commit instead of guessing an identity. Classify repositories outside the normal trees through an explicit repository-local include. Standard linked worktrees normally retain the identity of their main repository because their Git metadata remains below its `.git/worktrees` directory; test tool-created layouts such as the `work` CLI before relying on this.

Do not enable signing until the backup key exists, both keys are registered, clean-machine recovery has been tested, and the active private Git include selects the intended identity and signer.

### Recovery and revocation

The blank-machine recovery route must not require another configured Water Seven host or one available cloud account. Maintain:

1. the separately stored backup YubiKey;
2. personal Bitwarden as the convenient online source;
3. a sealed offline personal recovery kit containing password-manager recovery material, disk recovery credentials, a SOPS break-glass identity, and the personal credential-registration inventory.

Store the digital payload as a passphrase-encrypted, cross-platform archive on removable media. Give it a unique generated multiword passphrase that is not reused for Bitwarden, login, disk encryption, or hardware-token PINs. Keep two sealed paper copies of that passphrase in separate trusted locations, with neither copy stored beside the media or backup YubiKey. A personal Bitwarden copy is optional convenience, never the sole copy. Keep work credential inventory and recovery material only in work Bitwarden or another company-approved system.

Do not integrate hardware-backed LUKS, login, sudo, Git signing, or operator decryption while only one YubiKey exists. After the second key arrives, provision both together and test primary-key, backup-key, and recovery-only paths independently before enforcement.

Maintain a private credential inventory recording authority, purpose, host/device, public fingerprint or identifier, creation and last-test dates, recovery method, revocation procedure, and status. Personal entries live in personal Bitwarden with an encrypted offline copy; work entries live only in a company-approved system. Water Seven contains generic procedures and read-only checks, never the private inventory or automatic remote revocation.

Run a lightweight recovery drill every six months and after security-relevant changes. Verify paper records, recovery-media readability, non-sensitive decryption fixtures, fingerprints, registrations, and instructions without printing live secrets. Use disposable systems or temporary volumes for destructive scenarios; physical hosts use controlled alternative-path tests.

Rotate on disclosure, loss, compromise, offboarding or scope/policy changes, not merely because time passed. Provider-expiring credentials follow provider policy. A lost key triggers removal of every registered credential in its inventory, removal of its SOPS recipient, replacement-key provisioning, and recovery retesting. A compromised host triggers revocation of its sessions and generated tokens, rotation of every static secret it could decrypt, removal of its host recipient, and generation of a new host identity after reinstall.

## Bootstrap

Bootstrap is a **guided convergence** operation with one conceptual interface:

```text
bootstrap <host>                    # Current Mac or local NixOS installer
bootstrap <host> --target root@...  # Remote NixOS installer
```

The implementation detects the platform/execution mode.

### Shared behavior

- Host identity is an explicit argument.
- Default to the current `main` revision after CI passes.
- Permit `--rev` for recovery and diagnosis.
- Internet access is an initial requirement.
- Organize work into named, repeatable phases.
- Every phase checks its postcondition before acting.
- Rerunning skips completed phases and retries incomplete work.
- Terminal output is sufficient initially; no JSON report is required.
- When logout/reboot is required, persist enough progress to rerun the same command; do not install a privileged resume daemon.

Manual gate protocol:

1. Explain why the action is manual.
2. Open the relevant settings page where possible.
3. Wait for completion.
4. Verify through a reliable check when possible.
5. Otherwise request explicit confirmation.
6. Continue automatically.

### macOS

Use upstream Nix and let nix-darwin own Nix daemon configuration.

Accepted manual starting boundary:

1. Complete Setup Assistant.
2. Create the expected local administrator.
3. Connect to the network.
4. Enable FileVault and preserve its recovery key.
5. Open Terminal and invoke bootstrap.
6. Approve privacy/security prompts when guided.
7. Sign into Apple services manually when desired.

The public pre-Nix entrypoint stays minimal, installs upstream Nix when absent, fetches Water Seven, places it at the declared Projects path, and transfers control to a Nix-provided bootstrap application. The process performs initial nix-darwin activation and guides remaining permission/account work.

macOS cannot be pinned or rolled back by Nix. Support the currently installed stable release. OS upgrades are explicit and happen after compatibility checks. Security-data and malware-definition updates install automatically.

### NixOS

Start from a standard NixOS installer ISO with network access. Support both:

- Local installation using only the target machine and USB media
- Remote installation from another configured machine over SSH

Both paths consume the same host and Disko configuration through one install interface. Remote installation may use nixos-anywhere; the local adapter must implement equivalent installation without creating a second machine definition.

Destructive installation requires:

1. Explicit host selection
2. Explicit target-disk selection or confirmation
3. A concise partition/erase summary
4. Typing the host name to authorize erasure
5. Interactive entry of the LUKS secret

Routine activation is non-destructive and does not repeat these gates.

## `mini-merry`

`mini-merry` is the first machine to build and validate.

- Runs on the Apple Silicon Mac
- Uses native `aarch64-linux` virtualization
- Boots a complete Hyprland graphical workstation
- Is convenient and long-lived during development
- Contains no irreplaceable data and may be deleted at any time
- Uses LUKS2
- Receives explicitly scoped real secrets through a host-specific age key
- Treats VM snapshots/exports as sensitive
- Exercises both local and remote installation from a standard ISO
- Does not make virtual GPU behavior authoritative for `striker`

The VM envelope—CPU, memory, firmware, disk, networking, and hypervisor definition—should become declarative where practical, but that is deferred from the first bootstrapping work. Manual VM creation is acceptable initially.

The test role is **`egghead`**, reflecting an experimental/test environment. `shakedown` was rejected because it is not a One Piece reference.

## Activation and rollback

Workstations activate revisions explicitly. They do not automatically pull or switch configuration.

Activation pipeline:

1. Require a clean Git worktree.
2. Evaluate every supported host.
3. Run formatting, linting, UX-contract, and native-config checks.
4. Build the selected host.
5. Show a concise generation diff.
6. Prompt only for destructive or security-sensitive changes.
7. Switch the system generation.
8. Run post-activation checks.

Every deployed Nix generation records its source Git revision. Failed validation/builds leave the previous generation active.

### Coordinated rollback

Nix rollback alone is insufficient because native applications read directly from Git. A full rollback must coordinate both authorities:

1. Detect and preserve dirty edits in a clearly named Git stash.
2. Select a previously deployed revision.
3. Stop applications vulnerable to native/generated mismatch.
4. Check out the selected revision.
5. Activate/select its Nix generation.
6. Validate the recovered environment.
7. Report how to recover the preserved edits.

Use ordinary Git diff/restore for a broken uncommitted application edit. Coordinated rollback is for deployed revisions.

## Validation and CI

Require green CI before merging to `main`.

- Evaluate every host on every pull request.
- Run Nix formatting and linting.
- Check that every required UX action has an adapter implementation.
- Run native validators such as Ghostty configuration validation.
- Exercise native configuration startup where static validation is insufficient.
- Build `x86_64-linux` NixOS on a Linux runner.
- Build Apple Silicon Darwin configuration on a native macOS runner where practical.
- Build/test `aarch64-linux` guest outputs on a suitable runner.
- Run automated NixOS VM installation tests where practical.
- Periodically test macOS bootstrap in a disposable VM on Apple hardware.
- Keep physical smoke tests for privacy prompts, FileVault, displays, input, suspend, and rendering.

Dependency-update automation is deferred; updates are manual initially. Automatic merging is excluded. Third-party binary caching is deferred until measured build latency justifies it.

## Foundation completion criteria

The foundation is complete when all of the following work:

1. A clean revision evaluates all supported hosts.
2. `mini-merry` installs locally from a standard ISO.
3. `mini-merry` installs through the remote path.
4. `mini-merry` boots a complete Hyprland graphical session.
5. `mini-sunny` activates through nix-darwin and Home Manager in a macOS VM.
6. `baratie` activates successfully from Water Seven.
7. `striker` installs and boots from its declared Disko configuration.
8. Editing native Ghostty, Bash, tmux, and Neovim files requires no rebuild.
9. Shared desktop actions use the agreed physical layers on both platforms.
10. SOPS retrieval, host authorization, and runtime files work without plaintext leakage.
11. Guided bootstrap resumes safely after interruption.
12. Coordinated Git/Nix rollback restores a previous deployed revision.

## Explicitly deferred work

- Declarative VM envelope/hypervisor selection
- Offline recovery ISO and package closure
- Secure Boot/Lanzaboote
- Erase-on-boot impermanence
- Tailscale
- Inbound SSH for future desktop/server hosts
- Notifications and notification center
- Shared workspace indicators
- Device-specific keyboard normalization
- Atomic multi-monitor intent/workspace groups
- Automatic application-to-workspace placement
- Broader launcher features
- Application switching contract
- tmux resurrection after reboot
- Declarative browser profiles, groups, and containers
- Full communication/office/media/gaming application inventory
- Automated dependency-update pull requests
- Scheduled Git maintenance and repository registration; maintenance stays manual until a dashboard can expose run history and statistics
- Third-party binary cache

A deferred feature becomes active work only when a concrete workflow requires it or the existing design blocks implementation.
