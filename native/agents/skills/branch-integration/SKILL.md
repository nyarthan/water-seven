---
name: branch-integration
description: Rebase a committed branch; resolve an in-progress Git conflict; or review and commit scoped changes, rebase, validate, merge locally, and perform disclosed Workmux cleanup. Use when the user asks for one of these history-changing operations.
---

# Branch Integration

This skill provides three history-changing modes. Loading it grants no permission; the user's request must identify the authorized mode.

- **Rebase an already committed branch:** read [REBASE.md](REBASE.md).
- **Resolve the current merge or rebase conflict:** read [CONFLICTS.md](CONFLICTS.md).
- **Commit scoped work and merge the branch locally:** read [MERGE.md](MERGE.md).

## Shared preflight

Before any mode:

1. Inspect the current branch, status, worktrees, configured remotes, and relevant history.
2. Identify the intended base or target from the request and repository or Workmux configuration. Ask if it remains ambiguous.
3. Separate authorized task changes from unrelated, pre-existing, or unclear changes.
4. Stop before overwriting, stashing, staging, committing, or cleaning up work whose ownership is unclear.
5. Read the installed tool's current help before relying on Workmux-specific behavior.

Never force-push, skip safeguards, discard changes, or broaden the requested history operation without separate authorization.
