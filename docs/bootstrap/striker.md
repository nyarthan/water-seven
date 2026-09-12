# Bootstrap `striker`

`striker` is a company-owned Lenovo ThinkPad E14 Gen 6 (`x86_64-linux`) work workstation. Its reviewed installation target is the single 512 GB NVMe disk at `/dev/nvme0n1`. The installer USB appears separately as `/dev/sda`.

The installation destroys the entire NVMe disk and creates:

- a 1 GiB UEFI system partition;
- a LUKS2-encrypted ext4 root filesystem using the remaining space.

Disk encryption and the `jannis` login use separate interactive secrets. Neither belongs in the repository.

## Reviewed hardware facts

The live NixOS installer confirmed:

- UEFI boot with Secure Boot disabled;
- Intel Core Ultra 7 155H CPU and Intel Arc integrated graphics;
- Intel AX211 Wi-Fi and Bluetooth;
- Intel Ethernet, NVMe, Thunderbolt, camera, audio, touchpad, TrackPoint, battery, and TPM 2;
- working in-kernel drivers for graphics, Wi-Fi, Ethernet, NVMe, audio, NPU, and Thunderbolt.

The host configuration enables required initrd modules, Intel microcode and NPU support, redistributable firmware, Bluetooth, firmware updates, SSD trimming, thermal management, and power profiles. Fingerprint login remains undeclared until the Goodix reader is tested after installation.

## Install from the live image

Boot the official x86_64 NixOS installer in UEFI mode and connect networking. From another trusted machine, install an SSH public key into the temporary installer account if remote inspection is needed. Installed Water Seven disables inbound SSH.

In the installer as root:

```console
git clone https://github.com/nyarthan/water-seven.git /root/Projects/water-seven
cd /root/Projects/water-seven
export NIX_CONFIG="experimental-features = nix-command flakes"
nix run .#bootstrap -- striker
```

Bootstrap remains blocked by `deploymentReady = false` until company authorization for reinstalling the company-owned device is explicit. Once authorized and re-enabled, it performs a complete host build before asking for erasure approval. Check that its disk report identifies `/dev/nvme0n1` as the 512 GB NVMe device. To authorize destruction, type `striker` exactly, then enter a new LUKS passphrase twice. Later, set the independent login password for `jannis`.

An interrupted run recognizes only a LUKS partition carrying Water Seven's declared GPT partition label as resumable. Unrelated pre-existing encrypted disks are treated as destructive installation targets and still require explicit authorization.

## First boot

Remove the USB drive and reboot. Then verify:

1. The LUKS prompt accepts the new disk passphrase.
2. `jannis` can log in with the independent account password.
3. Greetd launches the Hyprland session.
4. `nmtui` can reconnect Wi-Fi; installer network credentials are not migrated.
5. Ghostty, tmux, Neovim, audio, brightness controls, touchpad, TrackPoint, and Wi-Fi work.
6. `systemctl --failed` reports no failed units.
7. `mole --version` reports the work-role Linux package version without requiring Homebrew.

Core first-boot validation has passed. Bluetooth and suspend/resume testing are explicitly deferred and do not block deployment readiness.

Secure Boot remains disabled until company authority over firmware, TPM, disk recovery, and signing-key custody is clarified and the staged preflight and recovery gates in [the `striker` Secure Boot and TPM design](../research/striker-secure-boot-tpm.md) pass. Do not infer authorization from the absence of MDM or combine Lanzaboote migration, firmware enforcement, measured-boot policy, and LUKS TPM enrollment in one change.
