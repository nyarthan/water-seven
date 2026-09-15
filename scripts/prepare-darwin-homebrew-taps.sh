#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <homebrew-prefix>\n' "$0" >&2
  exit 2
}

homebrew_prefix=${1%/}
taps="$homebrew_prefix/Library/Taps"

# nix-homebrew's immutable tap mode owns this path with a Nix-store symlink.
# Its repository migration intentionally preserves mutable tap state, which can
# leave an empty legacy directory behind and block that symlink.
if [[ -L $taps || ! -e $taps ]]; then
  exit 0
fi

if [[ ! -d $taps ]]; then
  printf 'error: %s exists and is not a directory; refusing Homebrew migration\n' "$taps" >&2
  exit 1
fi

shopt -s dotglob nullglob
entries=("$taps"/*)
if ((${#entries[@]} != 0)); then
  printf 'error: %s is not empty; preserve and reconcile its taps before migration\n' "$taps" >&2
  exit 1
fi

printf 'Removing empty legacy Homebrew taps directory %s.\n' "$taps"
rmdir "$taps"
