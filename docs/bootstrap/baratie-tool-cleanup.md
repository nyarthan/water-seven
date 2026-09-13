# `baratie` mutable tool cleanup

Use this checklist only after [the application and service migration](baratie-app-migration.md) has prepared `baratie` for Water Seven activation and the replacement or retirement decisions have been verified. The paths below were inventoried from metadata only; none of the unmanaged executables need to be run to complete the inventory.

## Verify the personal-role replacement

After activation, start a new login shell and confirm that Linearis resolves through the Home Manager generation rather than `~/.npm-packages/bin`:

```bash
type -a linear linearis
linear --version
linearis --version
```

Water Seven declares Linearis for the personal role. Its mutable authentication remains at `~/.linearis/token` and must not enter the Nix store.

## Verify work tools on `striker`

BWS, Claude Code, Headroom, OpenCode, TokenTracker, and the other work-role tools now belong on `striker`, not `baratie`. Verify their Nix-owned commands on `striker` before removing any mutable installation from `baratie` that is still needed for work continuity.

Do not add `~/.npm-packages/bin` or `~/.local/bin` to the managed `PATH` on either host.

## Remove replaced and retired installs

Once the relevant checks pass:

- Remove the global npm install of `linearis` from `baratie`; its personal-role replacement is Nix-owned. Preserve `~/.linearis/token`.
- Remove the global npm installs of `@anthropic-ai/claude-code`, `opencode-ai`, and `tokentracker-cli` after their work-role replacements are verified on `striker` and their local use on `baratie` is retired.
- Remove the rejected global npm installs `ccstatusline` and `eas-cli`.
- Remove `@opencode-ai/cli` if its legacy `lildax` command is no longer needed.
- Remove the uv tool `headroom-ai` after its replacement is verified on `striker`.
- Remove the standalone files or links `~/.local/bin/bws`, `~/.local/bin/claude`, and `~/.local/bin/tokensave` after the corresponding work workflow has moved. Remove `~/.local/share/claude/versions` only after confirming it contains executable versions rather than user configuration.
- Remove the dangling `~/.local/bin/awslocal` and `~/.local/bin/awslocal.bat` links.
- Confirm `~/.config/mise/config.toml` is Home Manager-owned and its global `[tools]` table is empty. Activation removes the old global ACLI and Aube declarations; remove their installed versions only after representative project toolchains pass.

Preserve application data and configuration while removing executable installations. In particular, this checklist does not authorize deletion of `~/.claude`, TokenTracker runtime data, or Headroom runtime data. Review whether that state is still required before transferring or deleting it; work credential material follows company policy and must not be copied into personal recovery storage.

## Completed pre-activation cleanup

The standalone `nixd` Nix profile entry was removed after a headless test confirmed that Water Seven Neovim attaches its bundled `nil` server to this flake. The still-active Tendril Neovim independently bundles its own `nixd`, so removing the redundant profile entry did not interrupt the current editor.

The rejected global npm packages `ccstatusline` and `eas-cli` and the dangling `~/.local/bin/awslocal{,.bat}` links were also removed. No application or credential state was deleted.

## Deferred items

Do not delete these until their separate migration decisions are complete:

- `@earendil-works/pi-coding-agent`, the custom pi fork.
- Unreferenced mise installation caches. Preserve them through initial activation; prune only after representative project-owned toolchains have been exercised.

The npm prefix can be removed only after every remaining package is either migrated or explicitly rejected.
