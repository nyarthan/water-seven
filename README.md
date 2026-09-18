# Water Seven

Declarative workstation configuration for a mixed-ownership fleet:

- `mini-merry` — `aarch64-linux` NixOS VM, `egghead` role
- `mini-sunny` — `aarch64-darwin` macOS VM, `egghead` role
- `baratie` — `aarch64-darwin` personal notebook
- `striker` — `x86_64-linux` company-owned work notebook

See [DESIGN.md](DESIGN.md) for the system design and
[the Dendritic architecture research](docs/research/dendritic-nix-architecture.md)
for the repository structure.

## Repository architecture

`flake.nix` evaluates every Nix file under `modules/` as a top-level
flake-parts module. Feature files contribute NixOS, nix-darwin, and Home
Manager modules to the shared, role, platform, and host profiles. The fleet
module is the sole place that turns those profiles into machine
configurations.

Non-flake modules, native application configuration, package expressions, and
test fixtures must live outside `modules/`.

## Agent configuration

Harness-neutral skills and context live under [`native/agents/`](native/agents/).
Pi-specific settings, extensions, and themes live under
[`native/pi/`](native/pi/). Home Manager deploys both collections while leaving
credentials, sessions, trust decisions, and caches under their runtime owners.

## Development

```console
nix fmt
nix flake check --all-systems --no-build
nix build .#checks.aarch64-darwin.host-baratie
nix build .#checks.aarch64-darwin.host-mini-sunny
nix develop
```

Host builds must run on a compatible native runner or builder. Use the guided
bootstrap app for activation:

```console
nix run .#bootstrap -- <host>
```

See [`docs/bootstrap/`](docs/bootstrap/) for platform-specific preparation and
validation.
