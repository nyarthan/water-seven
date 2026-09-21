---
name: worktree-orchestration
description: Create and coordinate isolated Workmux worktree agents. Use when the user asks to parallelize tasks, launch agents, monitor delegated work, or review their results. Branch integration remains a separate authorization.
compatibility: Requires the workmux CLI and a configured agent environment.
---

# Worktree Orchestration

This skill supplies Workmux procedure; it grants no authority. Route by the endpoint the user requested:

- **Delegate and stop after launch:** read [DISPATCH.md](DISPATCH.md).
- **Coordinate through completion and review:** read [COORDINATE.md](COORDINATE.md), which includes dispatch.
- **Integrate resulting branches:** use the `branch-integration` skill only when integration was explicitly requested.

## Shared invariants

- Give each worktree one coherent, independently executable task.
- Make prompts self-contained: agents do not inherit the coordinating conversation unless the selected Workmux mode explicitly provides it.
- Use repository-relative paths for files inside the assigned repository; preserve user-provided external paths exactly.
- State the requested phase and authority boundaries in every prompt. Do not tell a delegated agent to commit, publish, merge, deploy, or access sensitive data unless the user authorized that action.
- Use the installed `workmux --help`, subcommand help, configuration, and `workmux docs` as the command reference. Do not rely on cached flags.
- Preserve responsibility for every launched agent until reaching the endpoint the user requested.
