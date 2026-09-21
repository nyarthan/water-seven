# Local merge

This mode's disclosed contract is: review and commit scoped task changes, rebase onto the intended base, validate, merge locally, and perform applicable Workmux cleanup.

1. Inspect every staged, unstaged, and untracked path. Stop if any change is unrelated, pre-existing, generated unexpectedly, or otherwise unclear.
2. Run the relevant focused checks before committing. Stage explicit task paths rather than using blanket staging.
3. Review the staged diff and create a commit following repository conventions. The merge request authorizes this scoped commit, not additional cleanup.
4. Rebase onto the intended base by following [REBASE.md](REBASE.md). Resolve conflicts through [CONFLICTS.md](CONFLICTS.md).
5. Re-run the completion gate required by the changed surface.
6. If this is a Workmux-managed branch, inspect `workmux merge --help` and merge with the requested cleanup behavior. Otherwise perform the repository's normal local merge procedure without deleting branches or worktrees implicitly.
7. Confirm the target contains the integrated commits and report cleanup performed.

Do not push, publish a PR, approve, merge remotely, or deploy. Those are separate actions.
