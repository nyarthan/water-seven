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

Starting binding shape:

- Desktop-H/J/K/L: directional focus
- Desktop-Shift-H/J/K/L: directional movement
- Desktop-1…9: workspace selection
- Desktop-Shift-1…9: move window to workspace
- Desktop-F: floating toggle
- Desktop-Shift-F: maximize toggle
- Desktop-Space: launcher

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
- Provide an explicit plain-shell escape hatch.
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

Mise is installed and activated as a compatibility mechanism for projects that declare it. Prefer Nix development shells in projects under personal control. One project owns its toolchain; do not combine Nix and mise ownership for the same tools.

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

File managers, screenshots, and clipboard behavior remain platform-native initially. Browser profiles, groups/containers, history, and application accounts remain application-owned mutable state. Declarative browser profile/container management may be investigated later.

## Package acquisition

Use the first viable source in this order:

1. Stable nixpkgs package
2. Explicit nixpkgs-unstable exception when stable is inadequate
3. Project-owned custom Nix package when nixpkgs does not provide it
4. Declaratively managed Homebrew cask
5. Declaratively requested App Store application
6. Documented vendor/manual installation

The original discussion placed a custom Nix package immediately behind nixpkgs; an unstable nixpkgs exception is still a nixpkgs source and must be explicit.

On macOS:

- Explicit activation removes unlisted Homebrew packages using uninstall cleanup, not destructive zap cleanup.
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

Secure Boot is deferred. Investigate Lanzaboote after reproducible installation and LUKS2 work reliably. Record its threat model and recovery implications before enabling it.

Erase-on-boot impermanence is deferred. First prove reliable recovery from a blank disk.

Tailscale is deferred until remote access or VM connectivity becomes a real workflow.

## Secrets

Commit SOPS-encrypted secret files to the public repository. Ciphertext, filenames, recipient public keys, and metadata are public; plaintext and age private identities are not.

Rules:

- Filenames reveal as little sensitive information as practical.
- Plaintext never enters Git history, Nix store paths, logs, command arguments, or the clipboard.
- Secret requirements, owners, permissions, and target paths are declared publicly.
- Missing required secrets fail activation early and clearly.
- Decrypted values are exposed as protected runtime files.
- Process-local environment variables are derived at launch only when an application cannot consume a file.
- Evaluation and CI do not require decryption.

### Personal age identity

The two physical notebooks initially share one personal age recovery identity. Store it in Bitwarden and keep one tested encrypted offline recovery copy on removable media.

Install it at:

```text
~/.config/sops/age/keys.txt
```

with mode `0600`.

Bootstrap retrieval:

1. Nix provides `bitwarden-cli`.
2. Run interactive Bitwarden login and MFA when necessary.
3. Unlock the vault for the bootstrap process only.
4. Retrieve the `AGE-SECRET-KEY-...` value from the password field of a dedicated vault item.
5. Write it atomically without logs, shell tracing, clipboard use, or readable temporary files.
6. Derive its public key and decrypt a fixture as validation.
7. Clear the session and run `bw lock` in cleanup on success or failure.

### Host-specific recipients

Grant secrets per host and per file. Each SOPS file can retain the personal key as a recovery recipient while adding host keys for runtime use.

`mini-merry` receives real secrets but uses a host-specific age identity rather than the shared personal identity. It can decrypt only explicitly granted files. Its snapshots and exported disks are credential-bearing sensitive artifacts.

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
5. The Mac activates successfully from Water Seven.
6. `striker` installs and boots from its declared Disko configuration.
7. Editing native Ghostty, Bash, tmux, and Neovim files requires no rebuild.
8. Shared desktop actions use the agreed physical layers on both platforms.
9. SOPS retrieval, host authorization, and runtime files work without plaintext leakage.
10. Guided bootstrap resumes safely after interruption.
11. Coordinated Git/Nix rollback restores a previous deployed revision.

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
- Third-party binary cache

A deferred feature becomes active work only when a concrete workflow requires it or the existing design blocks implementation.
