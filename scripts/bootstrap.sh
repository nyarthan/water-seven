#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bootstrap <host> [--rev <revision>]
  bootstrap <host> --target root@<address> [--rev <revision>]

Without --target, bootstrap converges the current Mac or installs NixOS from a
local standard installer. With --target, it installs NixOS over SSH using
nixos-anywhere.
EOF
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

phase() {
  printf '\n==> %s\n' "$1"
}

confirm_erasure() {
  local host=$1 disk=$2 location=$3 answer
  printf '\nThis will erase %s on %s and create:\n' "$disk" "$location"
  printf '  - 1 GiB EFI system partition\n'
  printf '  - LUKS2-encrypted ext4 root partition\n\n'
  read -r -p "Type the host name '$host' to authorize erasure: " answer
  [[ $answer == "$host" ]] || fail "erasure was not authorized"
}

validate_install_disk_size() {
  local disk=$1 location=$2 size=$3
  local minimum_size=$((16 * 1024 * 1024 * 1024))
  [[ $size =~ ^[0-9]+$ ]] || fail "could not determine the size of $disk on $location"
  ((size >= minimum_size)) \
    || fail "$disk on $location is smaller than 16 GiB and may be installation media"
}

read_luks_secret() {
  local first second
  umask 077
  LUKS_SECRET_FILE=$(mktemp "${TMPDIR:-/tmp}/water-seven-luks.XXXXXX")
  read -r -s -p 'LUKS passphrase: ' first
  printf '\n'
  read -r -s -p 'Repeat LUKS passphrase: ' second
  printf '\n'
  [[ -n $first ]] || fail "the LUKS passphrase must not be empty"
  [[ $first == "$second" ]] || fail "the LUKS passphrases did not match"
  printf '%s' "$first" >"$LUKS_SECRET_FILE"
  unset first second
}

cleanup() {
  if [[ -n ${LUKS_SECRET_FILE:-} ]]; then
    rm -f -- "$LUKS_SECRET_FILE"
  fi
  if [[ -n ${LOCAL_LUKS_PATH:-} ]]; then
    rm -f -- "$LOCAL_LUKS_PATH"
  fi
  if [[ -n ${REVISION_WORKTREE:-} && -n ${REPOSITORY:-} ]]; then
    git -C "$REPOSITORY" worktree remove --force "$REVISION_WORKTREE" >/dev/null 2>&1 || true
  fi
  if [[ -n ${CHECKOUT_TRANSFER:-} ]]; then
    rm -rf -- "$CHECKOUT_TRANSFER"
  fi
}
trap cleanup EXIT INT TERM

[[ $# -gt 0 ]] || {
  usage
  exit 2
}
if [[ $1 == -h || $1 == --help ]]; then
  usage
  exit 0
fi

HOST=$1
shift
TARGET=
REVISION=
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)
      [[ $# -ge 2 ]] || fail "--target requires an SSH destination"
      TARGET=$2
      shift 2
      ;;
    --rev)
      [[ $# -ge 2 ]] || fail "--rev requires a Git revision"
      REVISION=$2
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) fail "unknown argument: $1" ;;
  esac
done

case $HOST in
  mini-merry | striker) PLATFORM=nixos ;;
  baratie | mini-sunny) PLATFORM=darwin ;;
  *) fail "unknown Water Seven host: $HOST" ;;
esac

REPOSITORY=$(git rev-parse --show-toplevel 2>/dev/null) || fail "run bootstrap from the Water Seven checkout"
[[ -z $(git -C "$REPOSITORY" status --porcelain) ]] || fail "bootstrap requires a clean Git worktree"

if [[ -n $REVISION ]]; then
  git -C "$REPOSITORY" rev-parse --verify "${REVISION}^{commit}" >/dev/null
  if [[ $PLATFORM == darwin && -z $TARGET ]]; then
    git -C "$REPOSITORY" checkout --detach "$REVISION"
    SOURCE=$REPOSITORY
  else
    REVISION_WORKTREE=$(mktemp -d "${TMPDIR:-/tmp}/water-seven-revision.XXXXXX")
    rmdir "$REVISION_WORKTREE"
    git -C "$REPOSITORY" worktree add --detach "$REVISION_WORKTREE" "$REVISION" >/dev/null
    SOURCE=$REVISION_WORKTREE
  fi
else
  [[ $(git -C "$REPOSITORY" branch --show-current) == main ]] || fail "default bootstrap requires the main branch; use --rev for recovery"
  SOURCE=$REPOSITORY
fi
DEPLOY_REVISION=$(git -C "$SOURCE" rev-parse HEAD)

if [[ -n $TARGET ]]; then
  [[ $PLATFORM == nixos ]] || fail "--target is supported only for NixOS hosts"

  STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}/water-seven/bootstrap
  REMOTE_MARKER=$STATE_HOME/$HOST-$DEPLOY_REVISION.remote-installed
  if [[ -e $REMOTE_MARKER ]]; then
    printf '%s at revision %s was already installed through the remote path.\n' "$HOST" "$DEPLOY_REVISION"
    exit 0
  fi

  phase "preflight"
  DISK=$(nix eval --raw "$SOURCE#nixosConfigurations.$HOST.config.disko.devices.disk.system.device" 2>/dev/null) \
    || fail "$HOST does not yet have a complete Disko configuration"
  ssh -o IgnoreUnknown=UseKeychain "$TARGET" test -b "$DISK" \
    || fail "$DISK is not a block device on $TARGET"
  DISK_SIZE=$(ssh -o IgnoreUnknown=UseKeychain "$TARGET" \
    lsblk --bytes --nodeps --noheadings --output SIZE "$DISK" | tr -d '[:space:]')
  validate_install_disk_size "$DISK" "$TARGET" "$DISK_SIZE"
  ssh -o IgnoreUnknown=UseKeychain "$TARGET" \
    lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,MOUNTPOINTS "$DISK"

  phase "destructive authorization"
  confirm_erasure "$HOST" "$DISK" "$TARGET"
  read_luks_secret

  phase "remote NixOS installation"
  nixos-anywhere \
    --phases kexec,disko,install \
    --flake "$SOURCE#$HOST" \
    --target-host "$TARGET" \
    --ssh-option IgnoreUnknown=UseKeychain \
    --disk-encryption-keys /tmp/water-seven-luks.key "$LUKS_SECRET_FILE"

  phase "install authoritative checkout"
  CHECKOUT_TRANSFER=$(mktemp -d "${TMPDIR:-/tmp}/water-seven-checkout.XXXXXX")
  git clone --quiet --no-hardlinks "$REPOSITORY" "$CHECKOUT_TRANSFER/water-seven"
  git -C "$CHECKOUT_TRANSFER/water-seven" checkout --quiet --detach "$DEPLOY_REVISION"
  ssh -o IgnoreUnknown=UseKeychain "$TARGET" \
    "rm -rf /mnt/home/jannis/Projects/water-seven && install -d -m 0755 -o 1000 -g 100 /mnt/home/jannis/Projects"
  tar -C "$CHECKOUT_TRANSFER" -cf - water-seven \
    | ssh -o IgnoreUnknown=UseKeychain "$TARGET" \
      "tar -xf - -C /mnt/home/jannis/Projects && chown -R 1000:100 /mnt/home/jannis/Projects/water-seven"

  phase "set the login password"
  printf 'Set the independent login password for jannis.\n'
  ssh -t -o IgnoreUnknown=UseKeychain "$TARGET" \
    "nixos-enter --root /mnt -c 'passwd jannis'"

  phase "reboot installed NixOS"
  ssh -o IgnoreUnknown=UseKeychain "$TARGET" systemctl reboot || true
  mkdir -p "$STATE_HOME"
  touch "$REMOTE_MARKER"

  printf '\nRemote installation complete. Remove installation media and boot %s.\n' "$HOST"
  exit 0
fi

if [[ $PLATFORM == darwin ]]; then
  [[ $(uname -s) == Darwin ]] || fail "$HOST must be bootstrapped from macOS"
  [[ $(id -un) == jannis ]] || fail "the expected local administrator is jannis"
  [[ $REPOSITORY == "$HOME/Projects/water-seven" ]] || fail "Water Seven must be checked out at $HOME/Projects/water-seven"

  phase "security preflight"
  fdesetup status | grep -q 'FileVault is On' || fail "enable FileVault and preserve its recovery key before bootstrap"

  phase "build $HOST"
  RESULT=$(mktemp -d "${TMPDIR:-/tmp}/water-seven-darwin.XXXXXX")/result
  nix build "$SOURCE#darwinConfigurations.$HOST.system" --out-link "$RESULT"

  phase "activate $HOST"
  sudo "$RESULT/sw/bin/darwin-rebuild" switch --flake "$SOURCE#$HOST"

  phase "post-activation checks"
  [[ $(scutil --get HostName) == "$HOST" ]] || fail "declared host name was not activated"
  dscl . -read /Users/jannis UserShell | grep -q '/bash' || fail "jannis does not have the declared Bash shell"

  printf '\n%s converged successfully. Log out and back in if prompted.\n' "$HOST"
  exit 0
fi

[[ $(uname -s) == Linux ]] || fail "$HOST must be installed from a NixOS installer"
[[ $(id -u) -eq 0 ]] || fail "local NixOS installation must run as root"
command -v nixos-install >/dev/null || fail "nixos-install is unavailable; boot a standard NixOS installer"

phase "preflight"
DISK=$(nix eval --raw "$SOURCE#nixosConfigurations.$HOST.config.disko.devices.disk.system.device" 2>/dev/null) \
  || fail "$HOST does not yet have a complete Disko configuration"
[[ -b $DISK ]] || fail "$DISK is not a block device"
DISK_SIZE=$(lsblk --bytes --nodeps --noheadings --output SIZE "$DISK" | tr -d '[:space:]')
validate_install_disk_size "$DISK" "this machine" "$DISK_SIZE"
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,MOUNTPOINTS "$DISK"

LOCAL_LUKS_PATH=/tmp/water-seven-luks.key
if mountpoint -q /mnt && [[ -e /dev/mapper/crypted ]]; then
  phase "partition, encrypt, and mount (already complete)"
elif lsblk -nrpo FSTYPE "$DISK" | grep -qx crypto_LUKS; then
  phase "remount existing encrypted installation"
  read_luks_secret
  install -m 0600 "$LUKS_SECRET_FILE" "$LOCAL_LUKS_PATH"
  disko --mode mount --flake "$SOURCE#$HOST"
else
  phase "destructive authorization"
  confirm_erasure "$HOST" "$DISK" "this machine"
  read_luks_secret
  install -m 0600 "$LUKS_SECRET_FILE" "$LOCAL_LUKS_PATH"

  phase "partition, encrypt, and mount"
  disko --mode destroy,format,mount --flake "$SOURCE#$HOST"
fi
rm -f "$LOCAL_LUKS_PATH"
LOCAL_LUKS_PATH=

if [[ -e /mnt/nix/var/nix/profiles/system ]]; then
  phase "install NixOS (already complete)"
else
  phase "install NixOS"
  nixos-install --flake "$SOURCE#$HOST" --no-root-password
fi

if [[ -d /mnt/home/jannis/Projects/water-seven/.git ]]; then
  phase "install authoritative checkout (already complete)"
else
  phase "install authoritative checkout"
  install -d -m 0755 -o 1000 -g 100 /mnt/home/jannis/Projects
  git clone --no-hardlinks "$REPOSITORY" /mnt/home/jannis/Projects/water-seven
  git -C /mnt/home/jannis/Projects/water-seven checkout --detach "$DEPLOY_REVISION"
  chown -R 1000:100 /mnt/home/jannis/Projects/water-seven
fi

PASSWORD_HASH=$(nixos-enter --root /mnt -c 'getent shadow jannis' | cut -d: -f2)
if [[ -n $PASSWORD_HASH && $PASSWORD_HASH != '!' && $PASSWORD_HASH != '*' ]]; then
  phase "set the login password (already complete)"
else
  phase "set the login password"
  printf 'Set the independent login password for jannis.\n'
  nixos-enter --root /mnt -c 'passwd jannis'
fi

printf '\nLocal installation complete. Reboot after removing installation media.\n'
