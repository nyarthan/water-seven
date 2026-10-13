# Pi resources

Pi-specific configuration lives here; shared agent policy, skills, and context live in [`../agents/`](../agents/).

Home Manager deploys `settings.json`, `keybindings.json`, `extensions/`, and `themes/` from this directory into `~/.pi/agent`. It generates the role-scoped `mcp.json` from [`modules/features/development/pi.nix`](../../modules/features/development/pi.nix) and deploys the shared global policy as `AGENTS.md`. These resources are declarative and read-only after activation. Change them in Water Seven and rebuild rather than saving persistent changes through Pi's interactive configuration screens.

Pi continues to own mutable runtime state such as authentication, MCP OAuth tokens, sessions, project trust decisions, model metadata, caches, and package downloads.

## OpenAI accounts

The `codex-accounts` extension exposes the built-in `openai-codex` provider as **OpenAI Codex (Personal)** and adds an independent `openai-codex-work` provider as **OpenAI Codex (Work)**. Their OAuth credentials remain separate entries in Pi's mutable `auth.json`.

Use `/login` to configure either provider. The existing `openai-codex` credential remains the personal credential, so only **OpenAI Codex (Work)** normally requires a new login.

Pi selects the work provider anywhere below `~/Projects/bettermarks` and the personal provider everywhere else. Override that behavior with either:

- `/codex-account` during a session (or `/codex-account personal|work|auto`), or
- `pi --codex-account ask|personal|work|auto` at startup.

The footer includes `[personal]` or `[work]` beside Codex models so the active subscription is visible.

## Codemode and MCP

Codemode and `tool_search` are enabled together. Built-in tools remain available as ordinary tool calls, while MCP tools use `codemode` exposure: they add only a one-line server summary to the prompt and are reached either from a codemode script or by loading a matching direct tool through `tool_search`. Codemode output should filter or aggregate large MCP responses before returning them to the model.

Personal hosts receive the first-party Atlassian, GitHub, and Linear servers. Work hosts receive GitHub only, and credential-free test hosts receive none. Atlassian and Linear authenticate with Pi's OAuth flow:

```console
pi mcp login atlassian
pi mcp login linear
```

GitHub uses the active `gh` login as a credential broker. Water Seven retains `gh` for that purpose and as a manual fallback, but agent GitHub API work should normally use the MCP server. Run `pi mcp list` after authentication to verify connections without putting credentials in declarative configuration.

## Development

The nested TypeScript project exists only for extension development and validation. Run `devenv allow` once in this directory to enable automatic activation through the global Bash hook, then use its tasks:

```console
devenv tasks run pi:format-check
devenv tasks run pi:types
```

Pi supplies its extension API, TUI, and TypeBox modules at runtime. Other runtime dependencies, including Pi's AI provider library and Effect, are declared in `package.json` and packaged with the extensions by Nix; extensions do not depend on a user-managed `~/.pi/agent/node_modules` tree.
