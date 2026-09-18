# Pi resources

Pi-specific configuration lives here; shared agent skills and context live in [`../agents/`](../agents/).

Home Manager deploys `settings.json`, `keybindings.json`, `extensions/`, and `themes/` into `~/.pi/agent`. These resources are declarative and read-only after activation. Change them here and rebuild Water Seven rather than saving persistent changes through Pi's interactive settings.

Pi continues to own mutable runtime state such as authentication, sessions, project trust decisions, model metadata, caches, and package downloads.

## Development

The nested TypeScript project exists only for extension development and validation:

```console
mise run format:check
mise run types
```

Pi supplies its extension API, TUI, and TypeBox modules at runtime. Other runtime dependencies, including Effect, are declared in `package.json` and packaged with the extensions by Nix; extensions do not depend on a user-managed `~/.pi/agent/node_modules` tree.
