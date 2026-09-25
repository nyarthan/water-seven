# Pi resources

Pi-specific configuration lives here; shared agent policy, skills, and context live in [`../agents/`](../agents/).

Home Manager deploys `settings.json`, `keybindings.json`, `extensions/`, and `themes/` from this directory into `~/.pi/agent`. It deploys the shared global policy there as `AGENTS.md`. These resources are declarative and read-only after activation. Change them in Water Seven and rebuild rather than saving persistent changes through Pi's interactive settings.

Pi continues to own mutable runtime state such as authentication, sessions, project trust decisions, model metadata, caches, and package downloads.

## OpenAI accounts

The `codex-accounts` extension exposes the built-in `openai-codex` provider as **OpenAI Codex (Personal)** and adds an independent `openai-codex-work` provider as **OpenAI Codex (Work)**. Their OAuth credentials remain separate entries in Pi's mutable `auth.json`.

Use `/login` to configure either provider. The existing `openai-codex` credential remains the personal credential, so only **OpenAI Codex (Work)** normally requires a new login.

Pi selects the work provider anywhere below `~/Projects/bettermarks` and the personal provider everywhere else. Override that behavior with either:

- `/codex-account` during a session (or `/codex-account personal|work|auto`), or
- `pi --codex-account ask|personal|work|auto` at startup.

The footer includes `[personal]` or `[work]` beside Codex models so the active subscription is visible.

## Development

The nested TypeScript project exists only for extension development and validation. Run `devenv allow` once in this directory to enable automatic activation through the global Bash hook, then use its tasks:

```console
devenv tasks run pi:format-check
devenv tasks run pi:types
```

Pi supplies its extension API, TUI, and TypeBox modules at runtime. Other runtime dependencies, including Pi's AI provider library and Effect, are declared in `package.json` and packaged with the extensions by Nix; extensions do not depend on a user-managed `~/.pi/agent/node_modules` tree.
