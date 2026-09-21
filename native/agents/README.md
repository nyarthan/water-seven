# Shared agent resources

This directory contains resources that are independent of any particular agent harness.

## Global policy

[`AGENTS.md`](AGENTS.md) is the canonical policy kernel for agent behavior. Home Manager deploys the same file to Pi at `~/.pi/agent/AGENTS.md` and OpenCode at `~/.config/opencode/AGENTS.md`. Keep it limited to stable, cross-cutting rules; project constraints belong in project instructions and specialist procedures belong in skills.

Risk examples will live in a separate, progressively disclosed document once they have been collected. Until then, keep examples out of the kernel rather than inventing a premature taxonomy.

## Skills

`skills/` is the canonical capability collection. Harnesses consume it through the standard `~/.agents/skills` location. Pi and OpenCode both discover that location directly.

A skill earns its place by having a distinct trigger, changing agent behavior materially, recurring across work, and producing a recognizable outcome. Each skill represents one coherent invocation decision. Branch-specific procedure is progressively disclosed only when different invocations need different material.

Skills provide abilities, never authority. Automatic discovery authorizes nothing; explicit invocation authorizes only a clearly disclosed contract.

### Capability catalog

Decision and design:

- `decision-grilling`
- `research`
- `domain-modeling`
- `design-prototyping`
- `codebase-design`
- `architecture-assessment`
- `design-friction-resolution`

Engineering:

- `bug-diagnosis`
- `test-driven-development`
- `rust-imports`

Delivery and coordination:

- `worktree-orchestration`
- `branch-integration`
- `pull-request-publication`
- `session-handoff`

Agent system:

- `agent-guidance`

Code review and behavioral evaluation of the agent setup are intentionally deferred. They have no placeholder skills: add them only after their workflows and evaluation model are designed.

### Provenance

Third-party provenance is recorded in [`SOURCES.json`](SOURCES.json), with retained licenses under [`licenses/`](licenses/). Locally maintained derivatives preserve attribution whenever source wording or substantial structure remains. Independently authored replacements are recorded as Water Seven sources rather than being presented as upstream copies.

TWG's vendor-provided skills remain excluded because their license prohibits retained and modified copies. Water Seven may contain independently authored TWG workflows based on user requirements, public documentation, and live CLI help, but not copies or derivatives of vendor skills.

Run `ruby scripts/check-skills.rb skills` to validate frontmatter, names, uniqueness, invocation metadata, and relative Markdown links.

## Context

`CONTEXT.md` and `docs/` contain harness-neutral vocabulary and design material. Harness adapters decide which material, if any, belongs in an always-loaded context.
