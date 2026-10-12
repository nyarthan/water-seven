# Bootstrap `striker`

`striker` is a company-owned TUXEDO InfinityBook Max 16 Intel Gen10 (`x86_64-linux`) work workstation. Its reviewed installation target is the single 1 TB Samsung NVMe disk at `/dev/nvme0n1`. The installer USB appears separately as `/dev/sda`.

The installation destroys the entire NVMe disk and creates:

- a 1 GiB UEFI system partition;
- a LUKS2-encrypted ext4 root filesystem using the remaining space.

Disk encryption and the `jannis` login use separate interactive secrets. Neither belongs in the repository.

## Reviewed hardware facts

The live NixOS installer confirmed:

- UEFI boot with Secure Boot disabled and TPM 2 available;
- Intel Core Ultra 9 275HX CPU, Intel integrated graphics, and an NVIDIA GeForce RTX 5070 Mobile GPU;
- a 2880×1800 internal display connected to the Intel GPU;
- Intel AX211 Wi-Fi and Bluetooth, Realtek RTL8125 2.5 GbE, Thunderbolt 4, an SD card reader, camera, audio, touchpad, battery, and a 1 TB NVMe SSD;
- working in-kernel drivers for the Intel graphics, Wi-Fi, Ethernet, NVMe, audio, NPU, Thunderbolt, and SD card reader.

The host configuration enables the generated initrd modules, Intel microcode and NPU support, redistributable firmware, Bluetooth, TUXEDO keyboard and hardware support, firmware updates, SSD trimming, thermal management, and power profiles. Hyprland renders on the Intel GPU by default; the NVIDIA 595 open kernel module provides PRIME render offload through `nvidia-offload`.

## Install from the live image

Boot the official x86_64 NixOS installer in UEFI mode and connect networking. From another trusted machine, install an SSH public key into the temporary installer account if remote inspection is needed. Installed Water Seven disables inbound SSH.

In the installer as root:

```console
git clone https://github.com/nyarthan/water-seven.git /root/Projects/water-seven
cd /root/Projects/water-seven
export NIX_CONFIG="experimental-features = nix-command flakes"
nix run .#bootstrap -- striker
```

The replacement hardware configuration has built successfully on the target notebook and bootstrap is enabled. Bootstrap performs another complete host build before asking for erasure approval. Check that its disk report identifies `/dev/nvme0n1` as the 1 TB Samsung NVMe device. To authorize destruction, type `striker` exactly, then enter a new LUKS passphrase twice. Later, set the independent login password for `jannis`.

An interrupted run recognizes only a LUKS partition carrying Water Seven's declared GPT partition label as resumable. Unrelated pre-existing encrypted disks are treated as destructive installation targets and still require explicit authorization.

## First boot

Remove the USB drive and reboot. Then verify:

1. The LUKS prompt accepts the new disk passphrase.
2. `jannis` can log in with the independent account password.
3. Greetd launches the Hyprland session.
4. `nmtui` can reconnect Wi-Fi; installer network credentials are not migrated.
5. Ghostty, tmux, Neovim, audio, brightness controls, keyboard backlight, touchpad, and Wi-Fi work.
6. `nvidia-smi` detects the RTX 5070 and `nvidia-offload` can run a graphical program.
7. `systemctl --failed` reports no failed units.
8. `mole --version` reports the work-role Linux package version without requiring Homebrew.

These first-boot checks are pending for the replacement hardware. Bluetooth and suspend/resume testing may follow after the core checks.

Secure Boot remains disabled until company authority over firmware, TPM, disk recovery, and signing-key custody is clarified and the replacement hardware receives a dedicated review. The existing [Secure Boot and TPM design](../research/striker-secure-boot-tpm.md) describes the retired hardware and is not an activation procedure for this notebook.
