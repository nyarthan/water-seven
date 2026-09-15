# `baratie` mutable tool cleanup

Use this checklist only after [the application and service migration](baratie-app-migration.md) has prepared `baratie` for Water Seven activation and the replacement or retirement decisions have been verified. The paths below were inventoried from metadata only; none of the unmanaged executables need to be run to complete the inventory.

## Verify the personal-role replacements

After activation, start a new login shell and confirm that Linearis and the custom Earendil pi fork resolve through the Home Manager generation rather than `~/.npm-packages/bin`:

```bash
type -a linear linearis pi
linear --version
linearis --version
pi --version
```

Water Seven declares Linearis and pi for the personal role. Pi comes from the localized unstable package because stable nixpkgs would downgrade the pre-migration 0.85.1 installation. Their mutable authentication and user state remain outside the Nix store; in particular, `~/.linearis/token` must not enter public configuration.

## Retire work-only tools from `baratie`

BWS, Claude Code, Headroom, OpenCode, TokenTracker, and the other work-role tools belong on `striker`, not `baratie`. The owner explicitly waived a `striker` continuity gate for first `baratie` activation and accepted that the old commands stop resolving there. This does not authorize deleting credential or application state; review that state separately under company policy.

Do not add `~/.npm-packages/bin` or `~/.local/bin` to the managed `PATH` on either host.

## Remove replaced and retired installs

Once the relevant checks pass:

- Remove the global npm installs of `linearis` and `@earendil-works/pi-coding-agent` from `baratie`; their personal-role replacements are Nix-owned. Preserve `~/.linearis/token`.
- Remove the global npm installs of `@anthropic-ai/claude-code`, `opencode-ai`, and `tokentracker-cli` after their work-role replacements are verified on `striker` and their local use on `baratie` is retired.
- Remove the rejected global npm installs `ccstatusline` and `eas-cli`.
- Remove `@opencode-ai/cli` if its legacy `lildax` command is no longer needed.
- Remove the uv tool `headroom-ai` after its replacement is verified on `striker`.
- Remove the standalone files or links `~/.local/bin/bws`, `~/.local/bin/claude`, and `~/.local/bin/tokensave` after the corresponding work workflow has moved. Remove `~/.local/share/claude/versions` only after confirming it contains executable versions rather than user configuration.
- Remove the dangling `~/.local/bin/awslocal` and `~/.local/bin/awslocal.bat` links.
- Confirm `~/.config/mise/config.toml` is Home Manager-owned and its global `[tools]` table is empty. The old global ACLI and Aube declarations and the Homebrew Repomix and RTK formulae have no continuity requirement and may be removed during activation.

Preserve application data and configuration while removing executable installations. In particular, this checklist does not authorize deletion of `~/.claude`, TokenTracker runtime data, or Headroom runtime data. Review whether that state is still required before transferring or deleting it; work credential material follows company policy and must not be copied into personal recovery storage.

## Completed pre-activation cleanup

The standalone `nixd` Nix profile entry was removed after a headless test confirmed that Water Seven Neovim attaches its bundled `nil` server to this flake. The still-active Tendril Neovim independently bundles its own `nixd`, so removing the redundant profile entry did not interrupt the current editor.

The rejected global npm packages `ccstatusline` and `eas-cli` and the dangling `~/.local/bin/awslocal{,.bat}` links were also removed. No application or credential state was deleted.

The private Git identity was copied locally from the effective Tendril identity into mode-0600 `~/.config/git/identity`; no identity values entered Water Seven. The differing Atuin and Git-ignore files were preserved as adjacent `.before-water-seven` backups and replaced with their candidate contents so Home Manager will not fail after Homebrew activation. Atuin retains `enter_accept = true`; the old Claude-specific global ignore pattern was intentionally not migrated.

## Vendor-managed TWG and deferred cleanup

TWG remains vendor/updater-managed on `baratie`. Preserve `~/mise.toml`, `~/.config/twg`, the installation under `~/.local/share/mise/installs/twg`, and `com.atlassian.twg.upkeep`. Water Seven exposes only a narrow `twg` wrapper for the updater-managed `latest/twg` executable; it does not expose `~/.local/bin` or the full Mise installation tree.

Preserve unreferenced Mise installation caches through initial activation; prune only after representative project-owned toolchains have been exercised. The npm prefix can be removed only after every remaining package is either migrated or explicitly rejected.
