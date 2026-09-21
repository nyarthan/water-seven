# Rebase

A rebase request authorizes rewriting the current branch onto the named or configured base. It does not authorize committing dirty work, force-pushing, or merging.

1. Require a clean working tree. Do not automatically stash unknown changes; ask how to proceed if the tree is dirty.
2. Resolve the target. Use the configured Workmux base when applicable, otherwise the explicitly named local branch. Fetch only when the request names a remote target or separately authorizes refreshing it.
3. Inspect commits on both sides of the merge base so the intended integration is understood.
4. Run the rebase.
5. If conflicts occur, follow [CONFLICTS.md](CONFLICTS.md).
6. Run checks proportionate to the affected surface after the rebase succeeds.

Completion means the branch is rebased onto the intended target, clean, and verified to the reported extent. State whether the rewritten branch now requires an authorized force-push; do not perform one implicitly.
