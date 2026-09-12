# Declarative packaging for Linearis

## Question

How should Water Seven retain Linearis without exposing the mutable global npm prefix on `PATH`?

## Findings

Linearis publishes the `linearis` package to npm and exposes both `linear` and `linearis` from the same executable. The current stable release is 2026.8.0, requires Node.js 22 or newer, and has three direct runtime dependencies: Commander, GraphQL, and node-emoji.[^npm]

No Linearis package is available in the pinned nixpkgs package sets. Building the Git release directly is also inappropriate for an offline Nix build: upstream's preparation and prebuild flow intentionally regenerates types by introspecting Linear's live GraphQL API.[^prepare] The npm release is the upstream-built artifact, carries npm provenance, and contains the generated executable and schemas.

The published artifact omits its lock file. Water Seven therefore keeps a minimal lock file generated from the release's exact runtime dependency declarations and uses `buildNpmPackage` with fixed source and dependency hashes. Install checks exercise both executable names without accessing the private Linear token.

## Decision impact

The personal role receives Nix-owned `linear` and `linearis` commands; the work role intentionally does not. Authentication remains personal mutable application state in `~/.linearis/token`; it is neither read nor copied into the Nix store. Because `baratie` is the personal host, its old global npm installation can be removed only after the Nix-owned replacement is activated and verified there.

[^npm]: [npm registry metadata for `linearis` 2026.8.0](https://registry.npmjs.org/linearis/2026.8.0)
[^prepare]: [Linearis `v2026.8.0` preparation script](https://github.com/linearis-oss/linearis/blob/v2026.8.0/scripts/prepare.mjs)
