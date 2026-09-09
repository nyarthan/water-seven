# Creating `mini-sunny` in UTM

`mini-sunny` is a disposable `aarch64-darwin` workstation with the `egghead`
role. The UTM envelope and macOS installation are manual; nix-darwin and Home
Manager own the workstation configuration inside the guest.

## VM envelope

1. In UTM, choose **Create a New Virtual Machine → Virtualize → macOS**.
2. Let UTM download Apple's latest compatible IPSW.
3. Allocate at least 4 CPU cores, 8 GiB RAM, and an 80 GiB disk.
4. Select the Water Seven checkout as the VM's shared directory.
5. Enable clipboard sharing when both host and guest support it.
6. Complete macOS Setup Assistant with an administrator whose short username is
   exactly `jannis`.
7. Install all pending macOS updates, power off the VM, and duplicate or
   archive it as a clean recovery point.

Do not sign into personal cloud or password-manager accounts merely to validate
the workstation configuration.

## Security and developer prerequisites

Enable FileVault under **System Settings → Privacy & Security → FileVault** and
store its recovery key outside the repository. Confirm it from Terminal:

```console
fdesetup status
```

Install Apple's Command Line Tools if `git` requests them:

```console
xcode-select --install
```

Homebrew must not be installed manually. The Darwin platform activates its
pinned installation through `nix-homebrew`; nix-darwin then manages the
declared casks.

## Transfer and activate the selected revision

Mount UTM's VirtioFS share and clone the host checkout so the guest receives
local commits without requiring them to be pushed first:

```console
sudo mkdir -p /Volumes/WaterSeven
sudo mount_virtiofs share /Volumes/WaterSeven
mkdir -p ~/Projects
git clone --no-hardlinks /Volumes/WaterSeven ~/Projects/water-seven
cd ~/Projects/water-seven
./install mini-sunny
```

The bootstrap builds `darwinConfigurations.mini-sunny`, preserves shell files
modified by the official Nix installer, activates the result through
nix-darwin, integrates Home Manager, and changes the guest identity to
`mini-sunny`. It backs up only files containing the expected Nix installer
marker and leaves unrelated custom files for manual review. macOS may request
administrator credentials or privacy grants. Never place those credentials in
the checkout.

## Smoke test

UTM's exclusive input capture does not take precedence over global event taps
installed by AeroSpace on the physical host. Disable host AeroSpace while
exercising guest key bindings:

```console
aerospace enable off
```

Open a new guest login session after activation, then verify:

```console
scutil --get ComputerName
scutil --get HostName
scutil --get LocalHostName
git -C ~/Projects/water-seven status --short --branch
```

All three names must be `mini-sunny`, and the checkout must be clean. Then:

1. Grant the requested Accessibility permissions to AeroSpace and Raycast.
2. Confirm AeroSpace starts and exercise the shared focus, movement, workspace,
   floating, maximize, and launcher bindings.
3. Open Ghostty and confirm it enters tmux session `main`.
4. Run `bash --noprofile --norc` and confirm a clean diagnostic Bash starts.
5. Start Neovim and confirm its configuration loads without errors.
6. Edit a checkout-backed native file and verify native reload behavior without
   rebuilding.
7. Reboot and confirm FileVault unlock, login, and application startup.

Re-enable AeroSpace on the physical host after testing:

```console
aerospace enable on
```

Keep `mini-sunny` free of real secrets unless a later host-specific policy
explicitly grants them.
