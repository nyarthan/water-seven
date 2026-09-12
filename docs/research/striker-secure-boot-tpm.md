# Secure Boot and transparent TPM unlock for `striker`

## Question

How can `striker` use transparent TPM2-assisted LUKS2 unlock without reducing the machine to effectively unencrypted storage, while preserving NixOS generations, rollback, firmware updates, and blank-machine recovery?

## Recommendation

Adopt the design in three independently recoverable stages:

1. **Lanzaboote Secure Boot only.** Pin stable Lanzaboote v1.1.0, manually create and back up the Secure Boot key bundle, boot Lanzaboote once with Secure Boot disabled, then manually enroll the keys with Microsoft certificates retained.
2. **Measured Boot without LUKS enrollment.** Enable Lanzaboote's `systemd-pcrlock` integration initially for PCRs 4 and 7, inspect prediction coverage, and prove signed-generation boot and rollback before the TPM controls any disk key.
3. **Transparent TPM enrollment.** Manually add a TPM2 LUKS token bound to the validated pcrlock policy, without a TPM PIN, while retaining the existing passphrase keyslot permanently. Test normal automatic unlock, authorized rollback, PCR mismatch fallback, and rescue-media recovery.

Do not combine the stages in one activation. Do not use Lanzaboote's automatic key generation, automatic firmware enrollment, automatic reboot, or `autoCryptenroll` for the existing physical installation. Each trust transition needs an observable checkpoint and a tested reversal.

This deliberately deviates from Lanzaboote's workstation recommendation to add `--tpm2-with-pin=true`.[^lanzaboote-measured-guide] Water Seven accepts the trade-off already selected: after an authorized boot, the root filesystem is mounted behind the OS login without user input. The design still protects against SSD removal and unrecognized measured boot paths, but not against compromise of an authorized pre-login system.

## Current compatibility

`striker` already satisfies the static prerequisites:

- x86_64 NixOS on UEFI;
- systemd-boot;
- a 1 GiB ESP mounted at `/boot` with restrictive mount permissions;
- LUKS2 root at `/dev/disk/by-partlabel/disk-system-encrypted`;
- a retained passphrase keyslot;
- TPM 2 hardware reported during installation;
- `boot.initrd.systemd.enable = true` in the evaluated NixOS 26.05 configuration; and
- systemd 260.2, which contains `systemd-pcrlock` and TPM2 cryptsetup support.

Lanzaboote requires UEFI and systemd-boot before migration and warns that Secure Boot still has sharp edges, including possible unbootable states.[^lanzaboote-introduction] Stable v1.1.0 is the first release with `systemd-pcrlock` measured-boot support.[^lanzaboote-changelog]

The remaining hardware gate must be checked natively before configuration changes:

```console
bootctl status
systemd-analyze has-tpm2
sudo /run/current-system/systemd/lib/systemd/systemd-pcrlock is-supported
findmnt /boot
findmnt /
df -h /boot
efibootmgr -v
fwupdmgr security
```

`systemd-pcrlock is-supported` must return `yes`; its policy design requires TPM 2.0 `PolicyAuthorizeNV` support, version 1.38 or newer.[^systemd-pcrlock] Capture results locally without publishing TPM identifiers or full event logs.

## Trusted boot chain

The intended chain is:

```text
UEFI firmware
  -> Secure Boot verifies signed systemd-boot
  -> systemd-boot selects a signed Lanzaboote generation stub
  -> Lanzaboote verifies embedded hashes for kernel and initrd
  -> Lanzaboote supplies the embedded kernel command line
  -> PCR 4 represents the selected boot artifacts
  -> PCR 7 represents Secure Boot state and authority
  -> TPM policy authorizes LUKS key release
  -> systemd initrd mounts root
  -> greetd/login authenticates the user
```

Lanzaboote signs systemd-boot and per-generation EFI stubs. Its guide notes that separately stored kernel artifacts can remain unsigned because the signed stub verifies their hashes.[^lanzaboote-prepare] Its stub embeds the kernel command line and, with Secure Boot active, ignores an externally edited command line; without Secure Boot it measures a custom command line into PCR 4 so that it changes the policy state.[^lanzaboote-stub]

Set the systemd-boot editor off anyway. It removes a misleading interface and protects configurations outside the exact Secure Boot path even though the signed stub already rejects an external override when enforcement is active.

Secure Boot alone establishes which code firmware may start. Measured Boot records the exact accepted path and gates TPM release. Neither authenticates the user. Transparent TPM unlock therefore depends on a hardened OS login and minimal pre-login attack surface after root is mounted.

## PCR policy

The Linux TPM PCR registry defines the relevant registers as follows:[^pcr-registry]

| PCR | Meaning | Operational behavior |
|---|---|---|
| 0 | Core firmware executable code | Changes across firmware updates |
| 1 | Firmware data/platform configuration | Can change with hardware or firmware settings |
| 2 | Extension and option-ROM executable code | Can change with attached/pluggable hardware |
| 3 | Extension and option-ROM configuration | Often unstable across hardware changes |
| 4 | Boot loader and loaded boot artifacts | Changes by authorized NixOS generation/bootloader variant |
| 7 | Secure Boot state and enrolled authority | Changes when Secure Boot mode, PK, KEK, db, or dbx changes |

Lanzaboote supports PCRs 0, 1, 2, 3, 4, and 7. It describes PCR 4 as the most important measurement because its stub covers the initrd, kernel, and embedded command line; its measured-boot guide uses `[ 0 4 7 ]` and warns that 1, 2, and 3 may be flaky.[^lanzaboote-measured-explanation][^lanzaboote-measured-guide]

### Initial selection: PCR 4 and 7

Start with:

```nix
boot.lanzaboote.measuredBoot = {
  enable = true;
  pcrs = [ 4 7 ];
};
```

This binds transparent release to an expected Lanzaboote boot variant and the expected Secure Boot state/authority while avoiding immediate firmware-update coupling. Including Microsoft signing certificates does not by itself authorize a Microsoft-signed alternate loader to decrypt the disk: its different PCR 4 measurement is absent from the pcrlock policy.

### Deferred PCR 0 hardening

PCR 0 would additionally bind release to the exact measured firmware code. That improves resistance to firmware replacement, but a legitimate firmware update changes PCR 0. Systemd instructs operators to unlock the firmware-code component before updating and regenerate policy afterward; stale policy otherwise blocks TPM release.[^systemd-pcrlock]

Add PCR 0 only after one controlled firmware-update rehearsal has proven:

- policy relaxation before the update;
- recovery-passphrase boot when measurements unexpectedly change;
- policy regeneration under the new firmware; and
- return to transparent unlock.

PCRs 1, 2, and 3 remain excluded unless repeated native measurements prove stable and a specific threat justifies their operational cost. Systemd itself warns that firmware-configuration PCRs can include unstable values such as temperatures or voltages.[^systemd-pcrlock]

## Generations and rollback

`systemd-pcrlock` builds a policy from recognized component definitions and permits multiple variants, represented internally with TPM `PolicyPCR` and `PolicyOR`. This is specifically intended to authorize multiple kernel or bootloader versions.[^systemd-pcrlock]

Lanzaboote generates pcrlock components for installed boot artifacts and updates the TPM NV policy when the bootloader installation hook runs. Consequently:

- a newly built generation can be authorized before reboot;
- retained older generations can remain authorized for manual rollback; and
- selecting an unknown or modified generation should fail TPM release and fall back to the LUKS passphrase.

Every retained authorized generation is part of the trusted boot set. Keeping an old vulnerable generation therefore preserves a rollback attack path. Balance recovery against attack surface with an initial generation limit of **four**: current plus three prior entries. Lanzaboote/systemd-pcrlock enforce an absolute maximum of eight variants, and `/boot` has only 1 GiB.[^lanzaboote-measured-guide][^lanzaboote-module]

Before relying on rollback:

1. boot the newest signed generation with Secure Boot but no TPM enrollment;
2. select each retained generation from the boot menu;
3. confirm its signature and expected PCR prediction;
4. remove generations that should no longer remain trusted; and
5. monitor ESP space on every bootloader update.

Lanzaboote documents that ESP exhaustion or FAT corruption can make the machine unbootable and provides recovery through an older generation or a rescue image after disabling Secure Boot.[^lanzaboote-troubleshooting]

### Automatic boot assessment

Lanzaboote supports systemd-boot boot counting, and its test demonstrates falling back after repeated failed boots.[^lanzaboote-boot-counting] Systemd marks a counted entry good through `systemd-bless-boot` after `boot-complete.target`; its no-failures check is disabled upstream by default.[^automatic-boot-assessment]

Do not enable boot counting in the first Secure Boot/TPM change. First define what `striker` considers a successful workstation boot—at minimum multi-user state, greetd availability, and no failed critical system units—then test automatic fallback separately. Otherwise a generation can be blessed before the graphical workstation is actually usable.

## Secure Boot key authority

Lanzaboote uses `sbctl` keys under `/var/lib/sbctl`; the private key is root-readable and Lanzaboote consumes it through an external filesystem path, not a Nix store path.[^lanzaboote-prepare]

Treat this bundle as a high-value signing authority:

- generate it manually on `striker` only after the recovery path is prepared;
- keep the live bundle root-only on the LUKS-protected filesystem;
- add an encrypted copy to the personal recovery archive;
- record its public fingerprints in the private credential inventory;
- never put private keys in Git, SOPS, a derivation, logs, or command arguments; and
- rotate the firmware authority after suspected key exposure.

Loss of the signing bundle does not reveal disk plaintext, but it prevents signing new boot artifacts under the enrolled authority. Recovery then requires the LUKS passphrase, disabling Secure Boot to boot rescue media, resetting firmware to Setup Mode, and enrolling a replacement authority.

Set and preserve a UEFI supervisor password before relying on Secure Boot. It prevents an unattended attacker from casually disabling enforcement or changing boot authority, and it protects the owner from an evil-maid flow that replaces the boot path and waits for the recovery passphrase. Store its recovery record in personal Bitwarden and the offline recovery kit, never in Water Seven.

Use manual key enrollment and retain Microsoft certificates as Lanzaboote recommends for hardware whose option ROMs may depend on them. Do not select firmware options that clear the forbidden-signature database (`dbx`). An up-to-date dbx remains necessary to reject known vulnerable signed loaders.[^lanzaboote-enable]

## TPM policy and LUKS enrollment

`systemd-pcrlock` predicts accepted PCR combinations and stores an authorization policy in a TPM NV index. The LUKS token is sealed via `PolicyAuthorizeNV`, allowing the NV policy to gain newly generated variants without re-enrolling the disk each generation.[^systemd-pcrlock]

The policy metadata at `/var/lib/systemd/pcrlock.json` is also encoded as a systemd credential on the ESP so the initrd can use it before root is mounted.[^systemd-pcrlock] It is operational state, not an independent recovery credential.

For the existing passphrase-only volume, perform the initial enrollment manually:

```console
sudo systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-with-pin=false \
  --tpm2-pcrlock=/var/lib/systemd/pcrlock.json \
  /dev/disk/by-partlabel/disk-system-encrypted
```

The command interactively requests an existing LUKS passphrase. Never supply it through a command argument or a repository file. Do not use `--wipe-slot=password`; the passphrase keyslot remains permanent.

Declare `tpm2-device=auto` through `boot.initrd.luks.devices.crypted.crypttabExtraOpts` if explicit discovery is needed. NixOS 26.05's systemd initrd supports systemd-cryptsetup hardware tokens and notes that enrolled LUKS2 metadata is usually discovered automatically.[^nixpkgs-luksroot] Do not set `headless`, because token failure must allow an interactive passphrase prompt.

Do not enable Lanzaboote `measuredBoot.autoCryptenroll` for this migration. Its service is designed to replace an existing TPM enrollment using `--unlock-tpm2-device=auto`; `striker` currently has only a passphrase slot. Manual enrollment makes the current passphrase authorization and resulting token observable.[^lanzaboote-module]

Systemd guarantees that older enrollments continue to work with newer systemd versions, but not necessarily that enrollments created by newer systemd work with older versions.[^systemd-cryptenroll] After a future systemd upgrade and TPM re-enrollment, an older NixOS generation may need the recovery passphrase even if its PCR variant remains authorized.

## Update behavior

### NixOS generation

Use `nixos-rebuild boot` for the first measured-boot updates. Lanzaboote installs and measures all retained boot artifacts, then `systemd-pcrlock make-policy` updates the TPM NV policy before reboot. If artifact installation or policy generation fails, do not reboot.

After reboot, verify the intended generation and only then use ordinary activation flow. A later dashboard may expose boot attempts and policy state, but the first deployment remains explicitly observed.

### Firmware and dbx

Firmware changes can affect PCR 0 when enabled. Secure Boot authority or dbx updates affect PCR 7 even without PCR 0. Before any firmware, dbx, or Secure Boot key update:

1. confirm the recovery passphrase works and is available;
2. inspect the planned PCR impact;
3. follow systemd's pcrlock unlock/update procedure where applicable;
4. expect the first changed boot may require the recovery passphrase;
5. regenerate and inspect the policy; and
6. prove transparent unlock on a subsequent reboot.

Lanzaboote adjusts `fwupd` to use a signed EFI updater under Secure Boot, but that does not remove PCR-change and recovery responsibilities.[^lanzaboote-module]

### Policy failure

Lanzaboote documents cases where policy updates fail after PCR changes. Its recovery procedure removes the stale pcrlock metadata, rebuilds the policy, and manually re-enrolls the TPM token.[^lanzaboote-troubleshooting] The independent LUKS passphrase is what makes that repair safe.

To disable measured boot, first remove the TPM2 LUKS slot, then disable measured-boot configuration and deallocate the pcrlock NV policy. Reversing that order can leave a stale token that no future boot policy can satisfy.[^lanzaboote-disable-measured]

## Suspend and physical state

Transparent TPM unlock protects a powered-off disk. Once booted, the LUKS key is in memory and the root filesystem is mounted. Suspend-to-RAM retains that state; it does not regain preboot protection.

`striker` currently has no declared swap and no hibernation design. Until suspend/resume and encrypted hibernation are reviewed:

- shut down before leaving the laptop in a higher-risk location or checked luggage;
- use immediate screen locking for short unattended periods; and
- treat theft of a booted or suspended host as compromise of locally available renewable credentials.

Secure Boot commonly enables Linux kernel lockdown, but validate the effective state natively rather than assuming it:

```console
cat /sys/kernel/security/lockdown
```

DMA/IOMMU state and whether the ThinkPad uses integrated firmware TPM or a discrete bus-connected TPM also belong in the native audit. They refine higher-skill physical attack analysis but do not replace the recovery-passphrase requirement.

## Staged deployment and validation

### Stage 0: read-only native audit

- Confirm `systemd-pcrlock is-supported`.
- Record current Secure Boot/setup mode, TPM, dbx, ESP use, boot entries, and firmware security report privately.
- Confirm the LUKS recovery passphrase through a controlled reboot before changing boot authority.
- Confirm current recovery media boots in UEFI mode.
- Prepare the recovery archive and UEFI supervisor-password record.

### Stage 1: signed boot, enforcement still off

- Pin Lanzaboote v1.1.0 to the existing nixpkgs input.
- Set a four-generation limit and disable the boot editor.
- Generate and back up `/var/lib/sbctl` manually.
- Switch from the NixOS systemd-boot module to Lanzaboote.
- Build with Secure Boot still disabled.
- Verify all expected EFI artifacts with `sbctl verify`.
- Reboot and test current and prior signed generations while firmware enforcement remains off.

### Stage 2: Secure Boot enforcement

- Set the UEFI supervisor password.
- Put the ThinkPad into Setup Mode without clearing dbx.
- Manually enroll the Water Seven keys plus Microsoft certificates.
- Reboot and verify `Secure Boot: enabled (user)` and signed artifact status.
- Test signed-generation rollback.
- Confirm that recovery media requires intentionally disabling Secure Boot with the supervisor password.

### Stage 3: measured policy, no disk token

- Verify pcrlock support again under enforced Secure Boot.
- Enable measured boot for PCRs 4 and 7.
- Build boot artifacts and inspect `systemd-pcrlock log`, components, prediction, and policy.
- Reboot current and retained generations and verify each predicted state.
- Do not enroll LUKS yet.

### Stage 4: transparent TPM token

- Reconfirm the passphrase unlock path.
- Manually enroll the TPM token without a PIN.
- Reboot and confirm automatic unlock.
- Boot each retained authorized generation and confirm automatic unlock.
- Disable Secure Boot temporarily: TPM release must fail and the passphrase prompt must succeed.
- Re-enable Secure Boot and confirm transparent unlock returns.
- Boot rescue media with Secure Boot intentionally disabled and prove manual LUKS access without modifying the installation.

### Stage 5: normal update and rollback

- Build one harmless new NixOS generation.
- Verify policy update before reboot.
- Boot and validate it.
- Select the previous generation and verify authorized transparent rollback.
- Roll forward and inspect failed units, PCR log, LUKS token metadata, and ESP space.

Only after all stages pass should transparent TPM unlock become normal `striker` behavior.

## Remaining decisions before implementation

The initial PCR set is `[ 4 7 ]`; PCR 0 remains deferred until a firmware-update rehearsal. Remaining decisions are:

1. Confirm a four-generation trusted/boot limit.
2. Decide whether Secure Boot key backup joins the same recovery archive or a separately encrypted archive.
3. Decide where the two physical recovery-passphrase envelopes and backup archive will be stored; locations remain private.
4. Decide whether automatic boot counting is a later feature or part of this project after a workstation boot-success target is defined.

## Sources

[^lanzaboote-introduction]: [Lanzaboote v1.1.0: Introduction](https://github.com/nix-community/lanzaboote/blob/v1.1.0/docs/introduction.md)
[^lanzaboote-changelog]: [Lanzaboote v1.1.0 changelog](https://github.com/nix-community/lanzaboote/blob/v1.1.0/CHANGELOG.md)
[^lanzaboote-prepare]: [Lanzaboote v1.1.0: Prepare your system](https://github.com/nix-community/lanzaboote/blob/v1.1.0/docs/getting-started/prepare-your-system.md)
[^lanzaboote-enable]: [Lanzaboote v1.1.0: Enable Secure Boot](https://github.com/nix-community/lanzaboote/blob/v1.1.0/docs/getting-started/enable-secure-boot.md)
[^lanzaboote-measured-explanation]: [Lanzaboote v1.1.0: Measured Boot](https://github.com/nix-community/lanzaboote/blob/v1.1.0/docs/explanation/measured-boot.md)
[^lanzaboote-measured-guide]: [Lanzaboote v1.1.0: Enable Measured Boot](https://github.com/nix-community/lanzaboote/blob/v1.1.0/docs/how-to-guides/enable-measured-boot.md)
[^lanzaboote-troubleshooting]: [Lanzaboote v1.1.0: Troubleshooting](https://github.com/nix-community/lanzaboote/blob/v1.1.0/docs/explanation/troubleshooting.md)
[^lanzaboote-disable-measured]: [Lanzaboote: Disable Measured Boot](https://github.com/nix-community/lanzaboote/blob/03bc477f555adfe314af48ec0d3554f10d3390d8/docs/how-to-guides/disable-measured-boot.md)
[^lanzaboote-module]: [Lanzaboote v1.1.0 NixOS module](https://github.com/nix-community/lanzaboote/blob/v1.1.0/nix/modules/lanzaboote.nix)
[^lanzaboote-stub]: [Lanzaboote v1.1.0 command-line selection](https://github.com/nix-community/lanzaboote/blob/v1.1.0/rust/uefi/stub/src/common.rs)
[^lanzaboote-boot-counting]: [Lanzaboote v1.1.0 boot-counting test](https://github.com/nix-community/lanzaboote/blob/v1.1.0/nix/tests/lanzaboote/boot-counting.nix)
[^systemd-pcrlock]: [systemd 260 `systemd-pcrlock`](https://www.freedesktop.org/software/systemd/man/260/systemd-pcrlock.html)
[^systemd-cryptenroll]: [systemd 260 `systemd-cryptenroll`](https://www.freedesktop.org/software/systemd/man/260/systemd-cryptenroll.html)
[^pcr-registry]: [UAPI Group: Linux TPM PCR Registry](https://uapi-group.org/specifications/specs/linux_tpm_pcr_registry/)
[^automatic-boot-assessment]: [systemd: Automatic Boot Assessment](https://systemd.io/AUTOMATIC_BOOT_ASSESSMENT/)
[^nixpkgs-luksroot]: [Pinned nixpkgs: LUKS root module](https://github.com/NixOS/nixpkgs/blob/5dfba6236110080a54247d6460bc2ff5dda939cc/nixos/modules/system/boot/luksroot.nix)
