# Creating `mini-merry` in UTM

The VM envelope is intentionally manual during the first bootstrap cycle. Its
NixOS installation and workstation state are declarative.

## VM envelope

1. Download the current stable **NixOS minimal ARM64 ISO** from
   <https://nixos.org/download/>.
2. In UTM, choose **Create a New Virtual Machine → Virtualize → Linux**.
3. Enable Apple virtualization and UEFI boot.
4. Allocate at least 4 CPU cores and 8 GiB RAM.
5. Create a 64 GiB or larger VirtIO disk.
6. Use shared/NAT networking with a VirtIO network device.
7. Use a VirtIO GPU/display with 3D acceleration when UTM offers it.
8. Add a serial device using UTM's built-in terminal. The declared kernel uses
   `hvc0` for the LUKS prompt and boot diagnostics under Apple virtualization.
9. Attach the ARM64 ISO as removable installation media and boot it.

Inside the installer, verify the target disk before continuing:

```console
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,MOUNTPOINTS
```

The declared configuration expects `/dev/vda`. Stop and update
`modules/hosts/mini-merry.nix` if UTM exposes another device; do not redirect
installation to an unverified disk.

Virtual rendering establishes that the desktop starts and is usable. It is not
authoritative evidence for `striker` graphics behavior.

## Local installation exercise

From the standard installer console:

```console
sudo -i
mkdir -p /root/Projects
nix-shell -p git --run \
  'git clone https://github.com/nyarthan/water-seven.git /root/Projects/water-seven'
cd /root/Projects/water-seven
nix --extra-experimental-features 'nix-command flakes' run .#bootstrap -- mini-merry
```

The bootstrap command displays the disk summary, requires typing
`mini-merry`, asks for the LUKS passphrase twice without echo, installs NixOS,
places the authoritative checkout at `/home/jannis/Projects/water-seven`, and
asks for the independent login password.

## Remote installation exercise

Boot a fresh copy of the same standard installer. At its console, set a
temporary root password and start SSH:

```console
sudo passwd root
sudo systemctl start sshd
ip address
```

From `baratie`, in a clean Water Seven checkout:

```console
nix run .#bootstrap -- mini-merry --target root@<installer-address>
```

Before rebooting, bootstrap leaves the installer environment running long
enough to transfer the selected Git checkout and set `jannis`'s independent
login password interactively. The checkout supplies native configuration files
referenced by Home Manager's out-of-store links. The installed configuration
disables inbound SSH, so installer credentials are temporary. A successful
remote install is recorded under
`$XDG_STATE_HOME/water-seven/bootstrap`; delete that marker only when
intentionally repeating the destructive remote exercise.

## First-boot smoke test

After removing the ISO and rebooting:

1. Unlock LUKS with the installation passphrase.
2. Sign in as `jannis` through greetd.
3. Confirm Hyprland, Waybar, wallpaper, audio controls, locking, and Fuzzel.
4. Open Ghostty and confirm it enters tmux session `main`.
5. Run `plain-shell` and confirm it opens Bash without tmux.
6. Exercise desktop focus, movement, workspaces, floating, maximize, and the
   launcher.
7. Edit the checkout-backed Bash, tmux, Neovim, Ghostty, Fuzzel, or Hyprland
   files and verify their native reload behavior without rebuilding.
