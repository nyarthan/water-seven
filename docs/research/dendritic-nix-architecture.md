# Dendritic Nix architecture for Water Seven

## Executive summary

Water Seven should use the **small, literal form of the Dendritic pattern**:

1. `flake.nix` is only the input manifest and top-level entry point.
2. Every `.nix` file under `modules/` is a flake-parts module and is imported once by `import-tree`.
3. Files are organized by **feature or decision**, not by module class or host.
4. Each feature contributes lower-level modules to a small fixed set of composition targets such as `shared-workstation`, `role-work`, `platform-darwin`, and `host-baratie`.
5. A typed `waterSeven.hosts` option records the three real hosts and holds their final deferred OS and Home Manager modules. One fleet module instantiates NixOS or nix-darwin and embeds Home Manager.
6. Cross-platform facts and the UX contract are top-level typed options. NixOS, nix-darwin, and Home Manager adapters consume those facts; one lower-level configuration must not discover policy by reading another finalized lower-level configuration.
7. Use flake-parts' optional `flake.modules` module initially. Do **not** begin with Den or flake-aspects: they solve real higher-order composition problems, but Water Seven's three known hosts and static profiles do not yet justify their additional model and fast-moving API.
8. Make every host build, policy assertion, and native validator a flake `check` on its native system. Add NixOS VM tests for runtime behavior and separate installer tests for Disko/bootstrap behavior.

This is consistent with [Water Seven's design](../../DESIGN.md): one pinned revision, integrated Home Manager generations, static profile composition, feature-level authority, three explicitly supported systems, local unstable exceptions, and no abstraction for hypothetical consumers.

## Evidence labels

This report distinguishes two kinds of statement:

- **Established** — directly documented or implemented by a primary source linked inline.
- **Recommendation / inference** — a conclusion for Water Seven drawn from those sources and from `DESIGN.md`; it is not part of the Dendritic definition.

Repository links are commit-pinned where useful. “Dendritic” by itself refers to the pattern documented by `mightyiam/dendritic`; “Den” is the separate `denful/den` framework.

## Origin and definition

**Established.** The idea was first presented publicly on 7 March 2025 as “every file is a flake-parts module,” after its author had used flake-parts for nine months and adopted the structure in `mightyiam/infra`. The discussion was later retitled to point to “the Dendritic Pattern,” and the author explicitly noted that it was no longer coupled to flake-parts ([originating NixOS Discourse thread](https://discourse.nixos.org/t/pattern-every-file-is-a-flake-parts-module/61271/1), [adoption commit](https://github.com/mightyiam/infra/commit/b45e9e13759017fe18950ccc3b6deee2347e9175)). The dedicated repository was announced in that thread in May 2025 ([announcement](https://discourse.nixos.org/t/pattern-every-file-is-a-flake-parts-module/61271/18)).

**Established.** The current definition is a Nixpkgs module-system usage pattern:

- evaluate a **top-level configuration**;
- import every non-entry-point Nix file directly as a module of that top-level configuration;
- let each file implement one feature across every lower-level configuration class it affects;
- store lower-level NixOS, nix-darwin, Home Manager, and similar modules/configurations as top-level option values; and
- use `deferredModule` value merging so multiple files can contribute to the same named lower-level module.

These are the defining statements in the [Dendritic README](https://github.com/mightyiam/dendritic/blob/6c76240658cf1c840faad557c0e0726064170a65/README.md#the-pattern). Flake-parts is the common top-level module system, but `lib.evalModules` or another module-system application can be used instead. Dendritic itself contains no implementation library.

The important distinction is therefore:

```text
Dendritic pattern              implementation choices
------------------------------ ------------------------------------
feature-oriented files         flake-parts or direct evalModules
one top-level module type      import-tree or a hand-written import
lower modules as option values flake.modules or project-owned options
cross-class feature closure    plain deferred modules, flake-aspects, Den, etc.
```

Automatic importing is convenient, but it is not the architecture's essence. The original discussion explicitly distinguishes Dendritic top-level modules from a tree of ordinary NixOS modules ([author clarification](https://discourse.nixos.org/t/pattern-every-file-is-a-flake-parts-module/61271/9)); a later example describes one remote-desktop feature defining both Home Manager application configuration and NixOS firewall configuration in the same file ([practitioner example](https://discourse.nixos.org/t/pattern-every-file-is-a-flake-parts-module/61271/17)). The latter is practitioner testimony, not a normative source.

## The underlying module-system mechanics

### Top-level and deferred lower-level evaluation

**Established.** `lib.evalModules` merges a list of modules into a typed configuration. It adds option declarations, type checking, composition, and extensibility to plain Nix ([Nixpkgs module-system chapter](https://github.com/NixOS/nixpkgs/blob/89a46b3d65147627f05d545579cecf3e14ecd59b/doc/module-system/module-system.chapter.md)). A module evaluation may declare a nominal `class`; imports with a different non-null `_class` are rejected by the [module loader](https://github.com/NixOS/nixpkgs/blob/89a46b3d65147627f05d545579cecf3e14ecd59b/lib/modules.nix#L451-L464). Nixpkgs recommends lower-camel-case class names, such as `nixos`.

**Established.** `lib.types.deferredModule` accepts a module value but does not evaluate it in the current option scope. When several definitions target the same option, its merge result is one module whose `imports` contain all definitions. `deferredModuleWith` can also supply static modules ([Nixpkgs implementation](https://github.com/NixOS/nixpkgs/blob/89a46b3d65147627f05d545579cecf3e14ecd59b/lib/types.nix#L1306-L1351)). This is the primitive that permits:

```nix
# feature A
flake.modules.homeManager.shared-workstation = { /* A */ };

# feature B, in a different top-level module
flake.modules.homeManager.shared-workstation = { /* B */ };
```

Both definitions become one deferred Home Manager module. They are not evaluated as Home Manager options until that merged value is imported into a Home Manager evaluation.

**Recommendation.** Treat the top-level flake-parts configuration as Water Seven's **composition plane** and each OS/Home Manager evaluation as an **execution plane**. Put fleet facts, the UX contract, package recipes, validators, and deferred modules in the composition plane. Put `services.*`, `programs.*`, `home.*`, and platform options only in the correct execution plane.

### Values crossing files and classes

**Established.** Top-level modules can share ordinary values through declared top-level options because all files participate in one top-level fixed point. This is the Dendritic alternative to forwarding internal values repeatedly through `specialArgs` and `home-manager.extraSpecialArgs` ([Dendritic anti-pattern discussion](https://github.com/mightyiam/dendritic/blob/6c76240658cf1c840faad557c0e0726064170a65/README.md#specialargs-pass-thru)).

There is an important nuance. The official module-system documentation says `specialArgs` is the mechanism for values needed while resolving `imports`; `_module.args` is available only after imports are resolved ([Nixpkgs documentation](https://github.com/NixOS/nixpkgs/blob/89a46b3d65147627f05d545579cecf3e14ecd59b/doc/module-system/module-system.chapter.md#module-system-lib-evalModules-param-specialArgs)). Official Home Manager documentation similarly recommends `extraSpecialArgs` for values originating outside its module graph ([NixOS integration](https://github.com/nix-community/home-manager/blob/a2dbe7c2c9333e8234ae8114c7f731784201d108/docs/manual/nix-flakes/nixos.md), [nix-darwin integration](https://github.com/nix-community/home-manager/blob/a2dbe7c2c9333e8234ae8114c7f731784201d108/docs/manual/nix-flakes/nix-darwin.md)). Thus “never use `specialArgs`” is a Dendritic design preference, not a general Nix rule.

**Recommendation.** In Water Seven:

- let a top-level feature module close over the specific `inputs` or facts its deferred modules need;
- declare shared authorities such as `waterSeven.ux.desktopActions` and `waterSeven.hosts` as typed top-level options;
- do not pass the whole `self`, `inputs`, or a generic unstable package set through every lower-level evaluation;
- use `specialArgs` only where import resolution or a third-party module genuinely requires externally supplied data.

This preserves origin information and avoids hidden global namespaces. Nixpkgs itself warns that more caller-supplied `evalModules` arguments make module sets less declarative and harder to relocate ([source comment](https://github.com/NixOS/nixpkgs/blob/89a46b3d65147627f05d545579cecf3e14ecd59b/lib/modules.nix#L78-L100)).

Do not make Home Manager policy depend on reading `nixosConfigurations.<host>.config`, or vice versa. A Dendritic discussion about machine-specific cross-class values reaches the safer answer: model shared metadata as a higher-level option rather than introspecting an already evaluated sibling configuration ([discussion #11](https://github.com/mightyiam/dendritic/discussions/11)). **Inference:** sibling evaluation reads create brittle recursion and reverse dependencies; a shared top-level authority is also the direct match for Water Seven's “every setting has one authority” rule.

## flake-parts and `flake.modules`

### What flake-parts contributes

**Established.** flake-parts describes itself as a minimal, module-system-based mirror of the standard flake schema. Its purpose is to split flake configuration into focused, reusable modules and handle system-scoped outputs ([README](https://github.com/hercules-ci/flake-parts/blob/31729ca8cbdb4fa927b34e5f4353e6a83f39e993/README.md)). `mkFlake` evaluates modules with class `flake`, and supplies `self`, `inputs`, `flake-parts-lib`, and `moduleLocation` as top-level special arguments ([implementation](https://github.com/hercules-ci/flake-parts/blob/31729ca8cbdb4fa927b34e5f4353e6a83f39e993/lib.nix#L60-L139)).

`perSystem` is for outputs such as packages, checks, apps, and dev shells that exist once per target system. Machine configurations are top-level entities, not `perSystem` entities; `withSystem` and `moduleWithSystem` bridge from a machine or lower-level module to the relevant per-system context ([official system guide](https://github.com/hercules-ci/flake.parts-website/blob/71970b431ae9cce1ae96db17d26583327bd2be2b/site/src/system.md), [module arguments](https://github.com/hercules-ci/flake.parts-website/blob/71970b431ae9cce1ae96db17d26583327bd2be2b/site/src/module-arguments.md)).

**Recommendation.** Put Water Seven's formatter, checks, packages, apps, and development shell in `perSystem`. Keep `nixosConfigurations`, `darwinConfigurations`, host records, and profile composition at top level. Use `withSystem` only when a host needs a package produced by Water Seven's corresponding `perSystem`; otherwise let the lower-level `pkgs` be authoritative.

### `flake.modules`

**Established.** `flake.modules` is an **optional**, not core, flake-parts module. It must be enabled with:

```nix
imports = [ inputs.flake-parts.flakeModules.modules ];
```

The option has type `lazyAttrsOf (lazyAttrsOf deferredModule)`. The outer key is a module class, the inner key is a module name, and each result is wrapped with `_class` and useful source-location metadata. `generic` is the special class-less namespace ([flake-parts source](https://github.com/hercules-ci/flake-parts/blob/31729ca8cbdb4fa927b34e5f4353e6a83f39e993/extras/modules.nix)). The resulting values are also exposed as flake output `modules.<class>.<name>`.

Use `config.flake.modules` while composing the same flake. Do not import a module back from `self`: flake-parts explains that importing from `self` can make the very output being constructed affect its own construction ([dogfooding guide](https://github.com/hercules-ci/flake.parts-website/blob/71970b431ae9cce1ae96db17d26583327bd2be2b/site/src/dogfood-a-reusable-module.md)). Published consumers may use `inputs.some-flake.modules.<class>.<name>`.

**Recommendation.** Use these class names consistently:

- `nixos`
- `darwin`
- `homeManager`
- `flake` only for intentionally published flake-parts modules

Use `flake.modules` for the actual deferred class modules, but also declare Water Seven-specific typed options for the domain model (`waterSeven.hosts`, `waterSeven.ux`, secret requirements, application management tier). This addresses the Dendritic author's warning that using only generic storage options can fail to express the infrastructure's mental model ([Dendritic “Not declaring options” anti-pattern](https://github.com/mightyiam/dendritic/blob/6c76240658cf1c840faad557c0e0726064170a65/README.md#not-declaring-options)).

### Profile bundle granularity

**Established.** The Dendritic author warns against assigning every small lower-level module a unique public name: it proliferates names, lengthens imports, and requires every composition site to change whenever a feature is added or removed. Multiple files should instead merge contributions under a smaller number of distinct names ([lower-level module name proliferation](https://github.com/mightyiam/dendritic/blob/6c76240658cf1c840faad557c0e0726064170a65/README.md#lower-level-module-name-proliferation)).

**Recommendation.** Water Seven should use exactly the composition boundaries already specified by `DESIGN.md`:

```text
shared-workstation
role-work | role-private | role-egghead
platform-nixos | platform-darwin
host-mini-merry | host-baratie | host-striker
```

Feature files merge into these bundle names. For example, `features/terminal/ghostty.nix` may contribute to all three classes' `shared-workstation`; `features/browser/chrome.nix` contributes only to `homeManager.role-private` or the appropriate platform role bundles. Hosts import four references, not dozens of leaf feature names.

The VM role's confirmed One Piece name is `egghead`.

### Dependencies between features

**Maturity concern (community report, not a normative guarantee).** Re-importing one generated `flake.modules` value through several dependent modules has produced module-deduplication questions; discussion #25 links the behavior to flake-parts and Nix module-key issues and suggests explicit keys or a deduplicating composition layer ([Dendritic discussion #25](https://github.com/mightyiam/dendritic/discussions/25)). The current `flake.modules` wrapper assigns class and file metadata but, unlike `flakeModules`, does not assign an explicit `key` ([source comparison](https://github.com/hercules-ci/flake-parts/blob/31729ca8cbdb4fa927b34e5f4353e6a83f39e993/extras/modules.nix), [flakeModules source](https://github.com/hercules-ci/flake-parts/blob/31729ca8cbdb4fa927b34e5f4353e6a83f39e993/extras/flakeModules.nix)).

**Recommendation.** For the foundation, make profile bundles additive and import each selected bundle exactly once per host; do not create a second string-based dependency resolver. Where an optional feature has a genuine hard dependency, use a direct module reference and add an evaluation test that includes the dependency through two paths. If dependency DAGs become common, adopt the tested resolution in flake-aspects rather than growing ad hoc deduplication logic.

## Cross-class composition

### NixOS and nix-darwin

**Established.** `nixpkgs.lib.nixosSystem` and `nix-darwin.lib.darwinSystem` each evaluate a lower-level module graph. nix-darwin's evaluator declares class `darwin`, checks release compatibility with Nixpkgs, and exposes `configuration.config.system.build.toplevel` as `configuration.system` ([nix-darwin evaluator](https://github.com/nix-darwin/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/eval-config.nix)). Its release check requires matching nix-darwin and Nixpkgs release branches; the flake input should follow the same Nixpkgs input.

**Recommendation.** A single `fleet/configurations.nix` should filter `waterSeven.hosts` by class and instantiate the correct evaluator. Each host record should contain:

- immutable identity: name, class, system, role;
- its final `os` deferred module;
- its final `home` deferred module;
- only facts that genuinely vary (hardware report/path, disk module, primary user where needed).

This is an abstraction over two supported evaluators and three real hosts, not a framework for hypothetical users.

### Integrated Home Manager

**Established.** Home Manager provides separate `nixosModules.home-manager` and `darwinModules.home-manager` integration modules. Both create `home-manager.users.<name>` submodules of class `homeManager`; `home-manager.sharedModules` is appended to every user's module list. `useGlobalPkgs` makes Home Manager use the system's `pkgs`, and `useUserPackages` installs user packages through the system's user-package option ([official integration implementation](https://github.com/nix-community/home-manager/blob/a2dbe7c2c9333e8234ae8114c7f731784201d108/nixos/common.nix#L20-L160)). Integrated configurations rebuild as part of the NixOS or nix-darwin generation ([NixOS guide](https://github.com/nix-community/home-manager/blob/a2dbe7c2c9333e8234ae8114c7f731784201d108/docs/manual/nix-flakes/nixos.md), [Darwin guide](https://github.com/nix-community/home-manager/blob/a2dbe7c2c9333e8234ae8114c7f731784201d108/docs/manual/nix-flakes/nix-darwin.md)).

**Recommendation.** In each generated OS configuration:

1. import the appropriate official Home Manager OS module;
2. set `home-manager.useGlobalPkgs = true` so stable nixpkgs configuration and the unfree allowlist have one package-set authority;
3. set `home-manager.useUserPackages = true` if package placement semantics are acceptable;
4. assign the host record's merged Home Manager module to `home-manager.users.jannis`;
5. keep OS-specific values available to Home Manager only through its documented `osConfig`, and use that for generated facts—not for shared policy.

A feature may therefore be one top-level file:

```nix
# modules/features/shell/bash.nix
{ config, ... }:
{
  flake.modules.nixos.shared-workstation = { pkgs, ... }: {
    users.defaultUserShell = pkgs.bashInteractive;
  };

  flake.modules.darwin.shared-workstation = { pkgs, ... }: {
    programs.bash.enable = true;
    # Darwin-specific system shell registration belongs here.
  };

  flake.modules.homeManager.shared-workstation = { pkgs, ... }: {
    home.packages = [ pkgs.bashInteractive ];
    # Link/source the authoritative checkout-native bash files here.
  };
}
```

The concrete options must be verified during implementation; the point of the example is its evaluation shape.

### When richer cross-class tooling is justified

**Established.** `denful/flake-aspects` transposes author-oriented `<aspect>.<class>` values into `flake.modules.<class>.<aspect>`, resolves transitive `includes`, supports nested/parametric aspects, and can forward one class into a submodule of another—for example Home Manager into `nixos.home-manager.users.<name>` ([overview](https://github.com/denful/flake-aspects/blob/e5bbf7be955e8289d545c783673808b18d48c780/docs/src/content/docs/index.mdx), [forwarding guide](https://github.com/denful/flake-aspects/blob/e5bbf7be955e8289d545c783673808b18d48c780/docs/src/content/docs/guides/forward.mdx)). Den adds typed host/user/home entities, policies, context dispatch, and automatic instantiation ([core principles](https://github.com/denful/den/blob/d50f0fce6fc1a8ba00fd0d310746d0e8ecc2f70d/docs/src/content/docs/explanation/core-principles.mdx)).

**Recommendation / inference.** Do not adopt either for the foundation. Plain deferred-module merging handles Water Seven's static four-layer profile composition. Reconsider flake-aspects if real features develop reusable dependency DAGs or repeated Home Manager forwarding. Reconsider Den if host/user/home context routing becomes a dominant, repeated problem. Avoid building a local imitation first.

## `import-tree`

**Established.** `import-tree` recursively discovers module files and returns one module containing those files in `imports`. By default it accepts `.nix` paths and ignores any path containing `/_`; it offers explicit filter, regex, map, and scoped-import APIs ([README](https://github.com/denful/import-tree/blob/eb1b52eaecc57f7c136d07ae8a93e724dfecac46/README.md), [implementation](https://github.com/denful/import-tree/blob/eb1b52eaecc57f7c136d07ae8a93e724dfecac46/default.nix)). Its own test suite covers recursion, filtering, ignored paths, path accumulation, submodules, and scoped imports ([tests](https://github.com/denful/import-tree/blob/eb1b52eaecc57f7c136d07ae8a93e724dfecac46/tests.nix)).

Recommended entry point:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/<current-stable-branch>";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

    nix-darwin.url = "github:nix-darwin/nix-darwin/<matching-release-branch>";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/<matching-release-branch>";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, import-tree, ... }:
    flake-parts.lib.mkFlake { inherit inputs; }
      (import-tree ./modules);
}
```

Select the actual currently supported stable branches when implementation starts; nix-darwin's source explicitly enforces matching release families.

**Recommendations.**

- Invoke `import-tree` once, at the entry point.
- Keep all auto-imported `.nix` files as top-level flake modules.
- Put non-module package functions outside `modules/` (for example `packages/foo/package.nix`) or apply one explicit, documented filter such as excluding `*.package.nix`.
- Reserve `_support/` under `modules/` for deliberately non-imported fixtures/helpers only. Prefer ordinary top-level options/modules over scoped imports; scoped lexical injection makes a file's dependencies harder to see.
- Do not use `_disabled` renames as durable feature switches. Git removal, profile composition, or a typed temporary option is more auditable.
- Add new files to Git before evaluating a flake: a flake sourced from a Git worktree sees the Git-tracked source snapshot, a practical trap explicitly called out by Den's import-tree test tutorial ([Den CI tutorial](https://github.com/denful/den/blob/d50f0fce6fc1a8ba00fd0d310746d0e8ecc2f70d/docs/src/content/docs/tutorials/ci.mdx#L165-L174)).

## Naming and file organization

**Established.** Dendritic imposes no required directory layout. Paths name features and may be moved or split without changing evaluation; all imported files retain the same top-level module type ([Dendritic benefits](https://github.com/mightyiam/dendritic/blob/6c76240658cf1c840faad557c0e0726064170a65/README.md#benefits)). denful's Dendrix conventions are explicitly non-mandatory and intended mainly for sharing community module trees ([conventions](https://github.com/denful/dendrix/blob/ffea5e597bd1c5f8d35d51545c67cff984a0ff40/dev/book/src/Dendrix-Conventions.md)).

**Recommendation.** Use lower-case kebab-case feature paths and names that describe an owned behavior, not merely a package. Good examples for this repository are:

- `features/terminal/ghostty.nix`
- `features/native-iteration/bash.nix`
- `features/desktop/launcher.nix`
- `ux/desktop-actions.nix`
- `security/secrets.nix`
- `bootstrap/nixos-install.nix`

A package name is appropriate when the package itself is the feature. Keep large feature closures in a directory and split by coherent authority, while merging into the same profile bundle. Avoid parallel roots such as `modules/nixos/`, `modules/darwin/`, and `modules/home/`: they recreate the class-oriented scattering Dendritic is intended to remove.

## Checks and testing

**Established.** `perSystem.checks` is an attribute set of derivations built by `nix flake check` ([flake-parts implementation](https://github.com/hercules-ci/flake-parts/blob/31729ca8cbdb4fa927b34e5f4353e6a83f39e993/modules/checks.nix)). The Nix CLI validates recognized output schemas, evaluates `nixosConfigurations.<name>.config.system.build.toplevel`, and builds `checks.<system>.<name>`; `--all-systems` checks outputs for all systems and `--no-build` evaluates without building ([official `nix flake check` reference](https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake-check)). `darwinConfigurations` is not among the output schemas listed by that command, so a Darwin derivation must be placed in `checks.aarch64-darwin` if it is to be covered as a check.

Recommended check layers:

1. **Top-level/domain assertions (cheap evaluation).** Validate unique host names, supported systems, fixed username/home rules, stable-by-default package policy metadata, explicit unfree names, secret requirement completeness, and that every required UX action has both Linux and macOS adapters.
2. **Lower-level assertions.** Put platform-specific invariants close to the relevant NixOS, Darwin, or Home Manager module.
3. **Host derivations.** Expose:
   - `nixosConfigurations.mini-merry.config.system.build.toplevel` as `checks.aarch64-linux.host-mini-merry`;
   - `nixosConfigurations.striker.config.system.build.toplevel` as `checks.x86_64-linux.host-striker`;
   - `darwinConfigurations.baratie.system` as `checks.aarch64-darwin.host-baratie`.
4. **Static repository checks.** Formatter, Nix lint, dead-code/statix policy as selected, shell checks, and checks that generated fragments/native source ownership do not overlap.
5. **Native validators.** Build derivations that assemble the exact effective native configuration and run `ghostty +validate-config`; run application startup/headless checks for Neovim, tmux, Bash, and other tools where static validation is insufficient.
6. **NixOS runtime tests.** Use `pkgs.testers.runNixOSTest` for services, login/session prerequisites, UX adapter generation, and secret failure behavior; this is the current Nixpkgs-supported wrapper ([Nixpkgs implementation](https://github.com/NixOS/nixpkgs/blob/89a46b3d65147627f05d545579cecf3e14ecd59b/pkgs/build-support/testers/default.nix#L194-L211)).
7. **Installer/bootstrap tests.** Keep these distinct from ordinary NixOS VM tests: exercise the standard ISO, Disko erase gates, local and remote paths, interruption/resume, LUKS, and post-install boot for `mini-merry`.
8. **Native CI partitioning.** Evaluate all outputs on every PR, but build each host on a compatible native runner/builder, matching `DESIGN.md`. A Linux runner cannot establish macOS activation/privacy behavior, and a Darwin build cannot establish physical notebook suspend, display, or input behavior.

Avoid checks that merely return a derivation without forcing the relevant configuration value. A check should either be the host/runtime derivation itself or use `builtins.deepSeq`/an assertion before creating a trivial derivation. Keep secrets out of evaluation and CI, as the design requires.

## Best practices and anti-patterns

| Practice | Status and rationale |
|---|---|
| One top-level module per feature, touching several classes | **Established core pattern.** This is Dendritic's defining unit. |
| Merge feature contributions into a few profile bundles | **Established guidance.** Avoids lower-module name proliferation. |
| Declare project-domain options | **Established Dendritic guidance; recommended here.** Types make the host/UX/secret model explicit. |
| Importing a selected feature enables it | **Dendritic opinion, not general Nix doctrine.** The author calls ubiquitous `enable` options an anti-pattern when modules are explicitly selected ([source](https://github.com/mightyiam/dendritic/blob/6c76240658cf1c840faad557c0e0726064170a65/README.md#enable-options)). Keep `enable` only where a module is necessarily imported but behavior is genuinely optional. |
| Close over narrow top-level values | **Recommended.** Better than global `self`/`inputs` pass-through for internal composition. |
| Use `specialArgs` when imports genuinely require external data | **Officially supported exception.** Do not turn the Dendritic preference into dogma. |
| Read finalized sibling class configurations to derive policy | **Anti-pattern by inference.** Risks recursion and creates multiple authorities; define a shared top-level fact. |
| Give every leaf feature its own lower-module name | **Established anti-pattern.** Produces long, fragile host import lists. |
| Put NixOS modules, package functions, and arbitrary expressions together under unfiltered auto-import | **Anti-pattern by inference.** It destroys the “known type of every file” benefit and causes evaluation failures. |
| Organize primarily as `nixos/`, `darwin/`, `home-manager/` | **Anti-pattern for this design.** It fragments one cross-platform feature and adapter contract across class trees. |
| Place machine configurations in `perSystem` | **Contrary to flake-parts guidance.** Machines are top-level entities. |
| Import local modules through `self.modules` | **Contrary to flake-parts guidance.** Reference the defining value or `config.flake.modules` to avoid self recursion. |
| Use path names as implicit tags/dependency strings | **Avoid.** Paths should document features, not become a second untyped configuration language. |
| Hide durable state behind `/_disabled` | **Avoid.** It is invisible composition; use Git or explicit typed policy. |
| Generate `flake.nix` immediately with `flake-file` | **Not recommended for Water Seven.** First-party Dendritic examples do this successfully (for example [`mightyiam/infra`](https://github.com/mightyiam/infra/blob/1b629238e5385bdb3377d2f6330d279f9fb5e350/flake.nix)), but it adds another generated authority and dependency before the basic architecture is proven. |
| Build a general framework around three hosts | **Directly conflicts with `DESIGN.md`.** Add abstractions only where supported implementations vary. |

Flake-parts' reusable-module guidance also advises against assuming or traversing arbitrary inputs, recommends namespaced custom options, and warns that input traversal can force unnecessary dependency fetches ([best practices](https://github.com/hercules-ci/flake.parts-website/blob/71970b431ae9cce1ae96db17d26583327bd2be2b/site/src/best-practices-for-module-writing.md)). Water Seven is primarily a configuration rather than a reusable module, but narrow dependencies still improve evaluation and agent navigation.

## Tradeoffs, maturity, and compatibility

### Benefits

- Feature closure aligns with Water Seven's one-authority rule: shared declaration and platform adapters can be adjacent.
- Every imported file has one known type and can use the top-level module arguments.
- Deferred-module merging permits incremental feature splits without editing central imports.
- Typed top-level options can validate cross-platform contracts before host builds.
- Paths are documentation rather than loader semantics, so refactoring is cheap.

### Costs

- There are nested module systems. A function may be a flake module returning a deferred NixOS/Home Manager module function; error messages and argument scope require fluency with both levels.
- Automatic import makes inclusion implicit. Source search and good names replace a central import list.
- The top-level fixed point can produce non-obvious recursion if modules derive import structure from `config` carelessly.
- Cross-class composition is not automatic: plain Dendritic still needs explicit Home Manager forwarding and host instantiation.
- Overly broad bundle names can hide why a setting applies; overly narrow names recreate import-list sprawl.

### Maturity assessment

**Established.** The named pattern is young (publicly named in 2025), but its essential primitives are not bespoke: the Nixpkgs module system, `deferredModule`, flake-parts, NixOS, Home Manager, and nix-darwin perform the evaluation. The Dendritic repository itself is documentation only. flake-parts notes that Nixpkgs' `deferredModuleWith` was added in Nixpkgs 22.11 and currently requires a Nixpkgs lib of at least 23.05 ([flake-parts source/history](https://github.com/hercules-ci/flake-parts/blob/31729ca8cbdb4fa927b34e5f4353e6a83f39e993/lib.nix#L20-L56)).

`import-tree` and `flake.modules` are additional moving pieces and should remain lock-file pinned. Den is explicitly in a `v0.x`, fast-paced phase; its maintainers say releases are tested but users must read release notes and may face awareness-requiring changes ([Den versioning](https://github.com/denful/den/blob/d50f0fce6fc1a8ba00fd0d310746d0e8ecc2f70d/docs/src/content/docs/releases.mdx)). flake-aspects is smaller, but still an extra abstraction over deferred modules. These maturity facts support starting with the plain pattern, not rejecting the pattern itself.

Compatibility controls for Water Seven:

- Pin every input in one `flake.lock`.
- Align stable nixpkgs, Home Manager, and nix-darwin release families; make nix-darwin follow `nixpkgs`.
- Keep stable `pkgs` authoritative for OS and integrated Home Manager.
- Import unstable locally in the exceptional feature and expose only the selected package, never `pkgsUnstable` globally.
- Maintain the explicit unfree allowlist in the single package-set configuration.
- Pin state versions per host/user and change them only after reading upstream migration notes.
- Add compatibility updates as reviewed changes with all host evaluations and native-system builds.

## Recommended starting structure

```text
water-seven/
├── flake.nix                         # explicit inputs + mkFlake/import-tree only
├── flake.lock
├── DESIGN.md
├── docs/
│   └── research/
│       └── dendritic-nix-architecture.md
├── modules/                          # every .nix here is a flake-parts module
│   ├── meta/
│   │   ├── flake-parts.nix           # enable flake.modules; declare 3 systems
│   │   ├── nixpkgs.nix               # stable package policy + unfree allowlist
│   │   ├── formatting.nix
│   │   └── checks.nix                # host/native/policy check wiring
│   ├── fleet/
│   │   ├── schema.nix                # typed waterSeven.hosts/options
│   │   └── configurations.nix        # nixosSystem/darwinSystem + integrated HM
│   ├── hosts/
│   │   ├── mini-merry.nix            # VM/hardware/disk facts + four imports
│   │   ├── baratie.nix
│   │   └── striker.nix
│   ├── profiles/
│   │   ├── shared-workstation.nix    # only profile-wide policy not owned below
│   │   ├── roles/
│   │   │   ├── work.nix
│   │   │   ├── private.nix
│   │   │   └── egghead.nix
│   │   └── platforms/
│   │       ├── nixos.nix
│   │       └── darwin.nix
│   ├── ux/
│   │   ├── contract.nix              # typed action/support-level authority
│   │   ├── desktop-hyprland.nix      # Linux translation + completeness data
│   │   └── desktop-aerospace.nix     # macOS translation + completeness data
│   ├── features/
│   │   ├── shell/
│   │   │   ├── bash.nix
│   │   │   ├── interactive-tools.nix
│   │   │   └── tmux.nix
│   │   ├── editor/neovim.nix
│   │   ├── terminal/ghostty.nix
│   │   ├── desktop/
│   │   │   ├── hyprland.nix
│   │   │   ├── aerospace.nix
│   │   │   └── launchers.nix
│   │   ├── applications/baseline.nix
│   │   ├── security/baseline.nix
│   │   └── secrets/sops.nix
│   ├── bootstrap/
│   │   ├── interface.nix
│   │   ├── macos.nix
│   │   └── nixos-install.nix
│   └── rollback/coordinated.nix
├── packages/                         # callPackage expressions; not auto-imported
│   └── <package>/package.nix
├── native/                           # authoritative handwritten app config
│   ├── bash/
│   ├── ghostty/
│   ├── nvim/
│   └── tmux/
└── tests/
    ├── nixos/                        # runNixOSTest modules
    ├── install/                      # ISO/Disko/bootstrap tests
    └── fixtures/
```

The boundary is more important than exact names: `modules/` contains only top-level modules; `native/` contains mutable-at-checkout application authorities; `packages/` contains package functions; `tests/` contains lower-level test modules imported explicitly by top-level test features.

### Initial composition shape

A feature contributes to bundle modules:

```nix
# modules/features/terminal/ghostty.nix
{ /* top-level args */ ... }:
{
  flake.modules.nixos.shared-workstation = { /* Linux system portion */ };
  flake.modules.darwin.shared-workstation = { /* macOS system portion */ };
  flake.modules.homeManager.shared-workstation = { /* shared user portion */ };

  perSystem = { pkgs, ... }: {
    # Validator package/check assembly where appropriate.
  };
}
```

A host composes references rather than strings:

```nix
# conceptual shape for modules/hosts/mini-merry.nix
{ config, ... }:
let
  modules = config.flake.modules;
in
{
  waterSeven.hosts.mini-merry = {
    class = "nixos";
    system = "aarch64-linux";
    role = "egghead";

    os.imports = [
      modules.nixos.shared-workstation
      modules.nixos.role-egghead
      modules.nixos.platform-nixos
      modules.nixos.host-mini-merry
    ];

    home.imports = [
      modules.homeManager.shared-workstation
      modules.homeManager.role-egghead
      modules.homeManager.platform-nixos
      modules.homeManager.host-mini-merry
    ];
  };

  flake.modules.nixos.host-mini-merry = { /* VM and hardware facts */ };
  flake.modules.homeManager.host-mini-merry = { /* genuine user exception, if any */ };
}
```

`fleet/configurations.nix` is the sole materializer. It imports the relevant official Home Manager integration module, puts `host.os` into the OS graph and `host.home` under the fixed user, sets the target system/package policy, and emits `flake.nixosConfigurations` or `flake.darwinConfigurations`. `meta/checks.nix` then exposes every resulting host derivation under the matching `checks.<system>` and adds policy/native/runtime tests.

This is the recommended foundation: recognizably Dendritic, built from upstream module-system primitives, explicit about Water Seven's domain, and small enough to replace if experience disproves it.

## Primary-source snapshot consulted

- [`mightyiam/dendritic` at `6c76240`](https://github.com/mightyiam/dendritic/tree/6c76240658cf1c840faad557c0e0726064170a65)
- [`mightyiam/infra` at `1b62923`](https://github.com/mightyiam/infra/tree/1b629238e5385bdb3377d2f6330d279f9fb5e350), plus its original adoption commit
- [`hercules-ci/flake-parts` at `31729ca`](https://github.com/hercules-ci/flake-parts/tree/31729ca8cbdb4fa927b34e5f4353e6a83f39e993) and [official website source at `71970b4`](https://github.com/hercules-ci/flake.parts-website/tree/71970b431ae9cce1ae96db17d26583327bd2be2b)
- [`NixOS/nixpkgs` module-system source at `89a46b3`](https://github.com/NixOS/nixpkgs/tree/89a46b3d65147627f05d545579cecf3e14ecd59b)
- [`nix-community/home-manager` at `a2dbe7c`](https://github.com/nix-community/home-manager/tree/a2dbe7c2c9333e8234ae8114c7f731784201d108)
- [`nix-darwin/nix-darwin` at `4cff07d`](https://github.com/nix-darwin/nix-darwin/tree/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48)
- [`denful/import-tree` at `eb1b52e`](https://github.com/denful/import-tree/tree/eb1b52eaecc57f7c136d07ae8a93e724dfecac46)
- [`denful/flake-aspects` at `e5bbf7b`](https://github.com/denful/flake-aspects/tree/e5bbf7be955e8289d545c783673808b18d48c780)
- [`denful/den` at `d50f0fc`](https://github.com/denful/den/tree/d50f0fce6fc1a8ba00fd0d310746d0e8ecc2f70d)
- [`denful/dendrix` at `ffea5e5`](https://github.com/denful/dendrix/tree/ffea5e597bd1c5f8d35d51545c67cff984a0ff40)
