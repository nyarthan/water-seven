# Coordinate

Coordination includes the dispatch procedure in [DISPATCH.md](DISPATCH.md), then retains responsibility for the launched agents through review.

Maintain an explicit set of active handles. A canceled wait, user interruption, or completed side request does not clear that set.

1. Monitor active handles using current Workmux status and wait commands.
2. When an agent waits for input, inspect its question and provide only decisions supported by the user's request. Route consequential gaps back to the user.
3. When an agent finishes, capture its report and inspect its branch status and diff. Establish what changed, what was verified, and what remains uncertain.
4. Send bounded follow-up instructions to the same agent when its result is incomplete or incorrect; preserve session continuity where practical.
5. Keep completed branches isolated until integration is authorized. Reviewing a result does not authorize merging it.
6. Continue monitoring the remaining active handles after processing each completion.

Coordination is complete when every launched agent has reached a reviewed terminal state and the user has an accurate result for each branch. If integration was requested, invoke `branch-integration` separately for one branch at a time.
