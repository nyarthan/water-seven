# Water Seven

Declarative personal workstation configuration for:

- `mini-merry` — `aarch64-linux` NixOS VM, `egghead` role
- `baratie` — `aarch64-darwin` work notebook
- `striker` — `x86_64-linux` private notebook

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

## Development

```console
nix fmt
nix flake check --all-systems --no-build
nix build .#checks.aarch64-darwin.host-baratie
nix develop
```

Host builds must run on a compatible native runner or builder. Bootstrap and
activation commands have not been implemented yet; do not activate these
configurations directly.
