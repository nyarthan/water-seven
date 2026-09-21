# Conflict resolution

Resolve conflicts by preserving intent, not by mechanically choosing ours or theirs.

1. Inspect the operation state and list every conflicting path.
2. For each conflict, read the relevant commits, surrounding code, tests, and originating requirements on both sides.
3. State the two intents and whether they are compatible.
4. Resolve the smallest coherent result that satisfies both intents. When they conflict semantically or ownership is unclear, stop and ask instead of inventing behavior.
5. Stage only resolved paths belonging to the current conflict. Continue the merge or rebase when continuation is part of the authorized parent operation.
6. Repeat until no conflicts remain, then run checks covering the integrated behavior.

Abort remains a valid safety option when resolution would be speculative or the operation was started against the wrong target. Recommend it when appropriate, but do not abort without authorization if doing so could disturb user state.

Completion means the authorized operation has continued or completed, all conflict resolutions are explained by source intent, and verification is reported accurately.
