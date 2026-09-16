# `baratie` application and service migration

Use this checklist before setting `baratie.deploymentReady = true`. It migrates the personally owned Mac from Tendril, MAS, vendor installers, and unmanaged Homebrew to the selected Water Seven personal role without reading or deleting application databases, browser profiles, Keychain items, private keys, or credential contents.

Never use Homebrew `zap` cleanup or an application-cleaner tool during migration. Preserve mutable application state unless a separate deletion decision explicitly names it.

## Desired application ownership

### Nix-owned

- Bitwarden
- Google Chrome
- OrbStack
- ProtonVPN
- Raycast
- Scroll Reverser
- Slack
- UTM
- WhatsApp from the localized unstable package set
- AeroSpace
- Linearis commands

Ghostty remains the one explicitly trusted Homebrew cask allowed to bypass quarantine.

### Declarative Homebrew casks

- Affinity
- AusweisApp
- Brave
- ChatGPT
- Helium Browser (`helium-browser`)
- LibreOffice
- Microsoft Teams
- Steam
- TablePlus
- Yubico Authenticator

### Declarative MAS request

- P-touch Editor, application ID `1453365242`

### Documented mutable/manual installations

- Logi Tune, because its Homebrew cask launches an interactive installer
- Microsoft AutoUpdate, because its self-updater can advance beyond the Homebrew cask
- ScanSnap Home, because its package cask cannot safely adopt the existing vendor installation
- YubiKey Manager GUI; retaining the application does not authorize changing a YubiKey
- Factorio and Hollow Knight: Silksong, managed by Steam
- P-touch and ScanSnap device state and drivers

## Applications to retire

Retire these only through the staged procedure below:

- Microsoft Excel and Word
- Xcode, while retaining Command Line Tools
- Insta360 Studio
- Open Design
- Stirling-PDF
- Wootility
- Tailscale
- Termius
- Discord
- DockDoor
- Figma
- Gather
- Karabiner-Elements and its VirtualHID system extension
- Lens
- kitty
- WezTerm
- Zen
- Claude Code URL Handler
- Mos, Obsidian, qBittorrent, and VLC from the old personal-host installation; these now belong to the work role

Bitwarden, Slack, and WhatsApp currently have MAS copies. Google Chrome, ProtonVPN, Scroll Reverser, OrbStack, and several cask-selected applications currently have vendor/manual copies. Remove those old application bundles only after the selected replacement opens successfully and mutable state is still available.

AusweisApp 2.5.5 is Intel-only in both official macOS distributions. The App Store and Homebrew cask deliver byte-identical `x86_64` application artifacts, so changing sources does not avoid Rosetta or macOS's future-compatibility warning. Retain the Homebrew cask and re-evaluate when upstream publishes a native Apple-silicon desktop build.

## Background-service disposition

Keep:

- Nix daemon, nix-darwin activation, and the Linux builder
- AeroSpace and Raycast
- Logitech agents and daemons required by Logi Tune
- Microsoft AutoUpdate while Teams remains selected
- ScanSnap agents
- OrbStack privileged helper
- ProtonVPN network extension
- Steam support and cleanup processes required by the selected games
- Vendor-managed TWG state and `com.atlassian.twg.upkeep`; Water Seven exposes only a narrow wrapper for its updater-managed executable

Retire:

- `homebrew.mxcl.postgresql@16`
- `org.nixos.postgresql`
- `org.git-scm.git.hourly`, `.daily`, and `.weekly`
- stale `io.podman_desktop.PodmanDesktop`
- stale `us.zoom.ZoomDaemon`
- stale OBS Virtual Camera extension
- Tailscale login item and network extension
- Karabiner DriverKit extension and agents
- Figma, DockDoor, and Mos login items
- Google Updater after the Nix-owned Chrome build is verified
- Steam removal is cancelled because Factorio and Silksong depend on it

Stopping PostgreSQL does not authorize deleting its data. Preserve all PostgreSQL directories until a separate data-retirement decision.

## Phase 1: build without activation

From the Water Seven checkout:

```bash
nix flake check --all-systems --no-build
nix build .#checks.aarch64-darwin.host-baratie --no-link
```

Do not change `deploymentReady` yet.

## Phase 2: prepare Homebrew ownership

Homebrew already records Steam. The other selected casks may collide with same-named vendor or MAS application bundles during activation. Migrate them one at a time before first activation.

For each selected cask:

1. Quit the application.
2. Confirm its important mutable data is synchronized or otherwise recoverable without inspecting secret contents.
3. Try Homebrew adoption only when the installed artifact is byte-identical to the cask artifact:

   ```bash
   /opt/homebrew/bin/brew install --cask --adopt <cask>
   ```

4. If versions differ, use Homebrew's non-zapping replacement path:

   ```bash
   /opt/homebrew/bin/brew install --cask --force <cask>
   ```

5. Open the application and verify its existing user state before continuing.

The casks to migrate are:

```text
affinity
ausweisapp
brave-browser
chatgpt
helium-browser
libreoffice
microsoft-teams
tableplus
yubico-authenticator
```

Migrate one token per command. Brave's Homebrew cask preserves its upstream macOS signature, unlike the Nix package's unsigned app bundle; both use the same bundle identifier and user profile. The Teams package installer may request administrator approval. Do not bypass that prompt.

Logi Tune, Microsoft AutoUpdate, and ScanSnap Home are excluded from this list and remain vendor-managed. An attempted ScanSnap Home 4.0.0 cask migration safely stopped because the signed installer refuses to reinstall an existing same-version product. Microsoft AutoUpdate 4.85.26080216 was newer than Homebrew's 4.84.26071119 cask, so it was not downgraded for package-manager ownership. P-touch Editor remains MAS-managed. Be signed into the App Store before activation so nix-darwin can verify or request P-touch Editor.

## Phase 3: first Water Seven activation

After cask ownership is prepared and the build succeeds:

1. Review the complete diff and expected package removals.
2. Set `baratie.deploymentReady = true` in a dedicated commit.
3. Run guided bootstrap for `baratie`. Before nix-homebrew claims immutable tap ownership, the activation removes a legacy `Library/Taps` directory only when it is empty; files or existing taps stop activation for explicit reconciliation.
4. Complete interactive TCC, default-browser, network-extension, App Store, and installer prompts.
5. Reboot before cleanup.

Verify retained applications without changing their data:

```bash
for app in \
  'Affinity' 'AusweisApp' 'Bitwarden' 'Brave Browser' 'ChatGPT' \
  'Google Chrome' 'Helium' 'LibreOffice' 'Logi Tune' \
  'Microsoft Teams' 'OrbStack' 'P-touch Editor' 'ProtonVPN' \
  'Raycast' 'ScanSnapHomeMain' 'Scroll Reverser' 'Slack' 'Steam' \
  'TablePlus' 'UTM' 'WhatsApp' 'Yubico Authenticator' \
  'YubiKey Manager'; do
  open -Ra "$app" || printf 'missing: %s\n' "$app"
done
```

Also verify:

```bash
linear --version
linearis --version
/opt/homebrew/bin/brew list --formula
/opt/homebrew/bin/brew list --cask
/opt/homebrew/bin/brew services list
```

The personal role should have no Homebrew formulae after cleanup. Do not authenticate Linearis merely to test executable ownership.

## Phase 4: retire applications and services

Use vendor uninstallers for software with privileged components or system extensions:

- Tailscale: disconnect, sign out if appropriate, and use its supported uninstall flow; confirm its login item and network extension are gone in System Settings.
- Karabiner-Elements: use its official uninstaller; confirm the DriverKit extension and hidden VirtualHID manager are gone.
- Zoom: use the vendor cleanup path for the stale daemon rather than deleting only its plist.
- OBS Virtual Camera: remove the stale extension through the supported OBS/macOS flow; do not disable system-extension security globally.
- ScanSnap, Logitech, Microsoft, OrbStack, ProtonVPN, and Steam components remain because their applications are retained.

Before deleting Xcode, switch the active developer directory to the already installed Command Line Tools and verify it:

```bash
sudo xcode-select --switch /Library/Developer/CommandLineTools
xcode-select -p
clang --version
git --version
```

Then remove Xcode through Finder or its supported uninstall path. Do not remove `/Library/Developer/CommandLineTools`.

The stale user LaunchAgent registrations and plist files for PostgreSQL, scheduled Git maintenance, and Podman Desktop were removed before activation. Both PostgreSQL services were stopped, while `/opt/homebrew/var/postgresql@16` and `/var/lib/postgresql/17` remain preserved. Let Water Seven replace Tendril-managed AeroSpace, Raycast, and Home Manager applications. Do not manually edit launchd databases or run a global `sfltool resetbtm`.

Remove obsolete application bundles only after their replacements and dependent workflows pass. In particular:

- keep the 14 GiB Steam library while Factorio and Silksong depend on it;
- preserve browser profiles even when removing Zen;
- preserve application databases and login state when replacing MAS/vendor bundles with Nix or Homebrew builds;
- do not use `brew uninstall --cask --zap`; and
- follow [the mutable tool cleanup](baratie-tool-cleanup.md) separately.

## Phase 5: final validation

After cleanup and another reboot:

```bash
nix run .#bootstrap -- baratie
nix build .#checks.aarch64-darwin.host-baratie --no-link
/opt/homebrew/bin/brew bundle check
launchctl list | grep -E 'postgres|git-scm|podman|tailscale|karabiner|figma|DockDoor|Mos|zoom' || true
systemextensionsctl list
```

Expected remaining non-Apple extensions are only those belonging to retained applications, notably ProtonVPN. Confirm FileVault, SIP, the firewall, default browser, AeroSpace, Raycast, Ghostty, the Linux builder, and no unexpected login/background items before declaring migration complete.
