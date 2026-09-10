# Declarative packaging for TokenTracker and Headroom

## Question

How should Water Seven install the TokenTracker and Headroom command-line tools without retaining mutable global npm or uv tool directories on `PATH`?

## Findings

### TokenTracker

TokenTracker publishes the `tokentracker-cli` package to npm. The current npm release is 0.96.2, requires Node.js 20 or newer, and exposes `tracker`, `tokentracker`, `tokentracker-cli`, and `tokentracker-tracker` from one executable. Its runtime dependency set is small: `@mongodb-js/zstd`, `undici`, and `yauzl`.[^tokentracker-npm]

The corresponding upstream release is tagged `v0.96.2`. Its source tree contains both `package.json` and `package-lock.json`, which makes it suitable for a fixed-output `buildNpmPackage` derivation.[^tokentracker-release] nixpkgs documents `buildNpmPackage` as the standard builder for npm projects with a lock file and a fixed `npmDepsHash`.[^build-npm-package]

**Recommendation:** package TokenTracker directly in Water Seven with `buildNpmPackage`, pinning the upstream release and npm dependency hash. This keeps the executable and Node dependency closure in the Nix store while leaving TokenTracker's runtime data in its normal mutable user-data location.

### Headroom

Headroom publishes `headroom-ai` to PyPI. The current release is 0.37.0, requires Python 3.10 or newer, and exposes the `headroom` command.[^headroom-pypi] Its source distribution uses Maturin as the PEP 517 build backend and includes a Rust extension, so it is not a simple pure-Python wrapper.[^headroom-source]

The required base Python dependencies are available in the pinned unstable nixpkgs package set. The exceptional `ast-grep-cli` Python distribution can be replaced at runtime by nixpkgs's native `ast-grep` executable, provided the package metadata dependency is removed explicitly in the derivation. nixpkgs supports Python applications with `buildPythonApplication` and Maturin projects through its Maturin build hook.[^python-packaging][^maturin-hook]

**Recommendation:** create a local `buildPythonApplication` derivation from the pinned PyPI source distribution, use the Maturin/Cargo hooks, declare the Python dependency closure from the localized unstable package set, and supply `ast-grep` on the wrapped executable's `PATH`. Do not run `uv tool install` during activation: that would fetch mutable state outside the generation and weaken rollback.

## Decision impact

Both tools can be Nix-owned without exposing `$HOME/.npm-packages/bin` or `$HOME/.local/bin` globally. Their application data remains mutable, but their executable versions and dependencies become part of the workstation generation.

[^tokentracker-npm]: [npm registry metadata for `tokentracker-cli` 0.96.2](https://registry.npmjs.org/tokentracker-cli/0.96.2)
[^tokentracker-release]: [TokenTracker `v0.96.2` upstream release](https://github.com/xiufengsun/TokenTracker/releases/tag/v0.96.2)
[^build-npm-package]: [nixpkgs manual: `buildNpmPackage`](https://nixos.org/manual/nixpkgs/stable/#javascript-buildNpmPackage)
[^headroom-pypi]: [PyPI metadata for `headroom-ai` 0.37.0](https://pypi.org/pypi/headroom-ai/0.37.0/json)
[^headroom-source]: [Headroom `v0.37.0` upstream release](https://github.com/headroomlabs-ai/headroom/releases/tag/v0.37.0)
[^python-packaging]: [nixpkgs manual: building Python packages and applications](https://nixos.org/manual/nixpkgs/stable/#buildpythonpackage-function)
[^maturin-hook]: [nixpkgs Maturin build hook](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/python-modules/maturin/default.nix)
