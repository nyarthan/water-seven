# `baratie` mutable tool cleanup

Use this checklist only after Water Seven is approved for `baratie`, activated, and the replacement commands have been verified. The paths below were inventoried from metadata only; none of the unmanaged executables need to be run to complete the inventory.

## Verify Nix-owned replacements

After activation, start a new login shell and confirm that each command resolves through the Home Manager generation rather than `~/.npm-packages/bin` or `~/.local/bin`:

```bash
type -a bws claude headroom opencode tokentracker
bws --version
claude --version
headroom --version
opencode --version
tokentracker --version
```

Water Seven currently declares BWS, Claude Code, Headroom, OpenCode, and TokenTracker for the work role. Do not add either mutable bin directory to the managed `PATH`.

## Remove replaced and rejected installs

Once the checks above pass:

- Remove the global npm installs of `@anthropic-ai/claude-code`, `opencode-ai`, and `tokentracker-cli`; their replacements are Nix-owned.
- Remove the global npm install of `linearis`; it is intentionally private-role software and is not needed on `baratie`. Preserve `~/.linearis/token` unless its private state is explicitly retired.
- Remove the rejected global npm installs `ccstatusline` and `eas-cli`.
- Remove `@opencode-ai/cli` if its legacy `lildax` command is no longer needed.
- Remove the uv tool `headroom-ai`; its replacement is Nix-owned.
- Remove the standalone files or links `~/.local/bin/bws`, `~/.local/bin/claude`, and `~/.local/bin/tokensave`. Remove `~/.local/share/claude/versions` only after confirming it contains executable versions rather than user configuration.
- Remove the dangling `~/.local/bin/awslocal` and `~/.local/bin/awslocal.bat` links.
- Confirm `~/.config/mise/config.toml` is Home Manager-owned and its global `[tools]` table is empty. Activation removes the old global ACLI and Aube declarations; remove their installed versions only after representative project toolchains pass.

Preserve application data and configuration while removing executable installations. In particular, this checklist does not authorize deletion of `~/.claude`, TokenTracker runtime data, or Headroom runtime data.

## Deferred items

Do not delete these until their separate migration decisions are complete:

- `@earendil-works/pi-coding-agent`, the custom pi fork.
- Unreferenced mise installation caches. Preserve them through initial activation; prune only after representative project-owned toolchains have been exercised.
- The standalone `nixd` Nix profile entry; first confirm that no editor or project still selects it. Water Seven itself uses `nil`.

The npm prefix can be removed only after every remaining package is either migrated or explicitly rejected.
