# Process-review rubric

Use this reference after trace sampling. Judge the process used to reach the result, not whether the transcript contains interesting facts.

## Classification

| Class | Evidence threshold |
|---|---|
| `good` | Goal achieved; process was proportionate; no material uncorrected failure. Minor friction may remain. |
| `mixed` | Useful result, but avoidable friction, user correction, overreach, or missing verification materially affected the path. |
| `bad` | Goal was not achieved, unsafe/incorrect changes remained, or the process failed despite a recoverable path. |
| `trivial-skip` | No substantive goal or agent work exists. Record why and stop. |

A qualifier narrows the class; it does not replace it. Prefer `good-with-one-correction` over inventing a new base class.

## Friction taxonomy

- **Context**: necessary context was missing, stale, wrong, or loaded too broadly.
- **Navigation**: the agent chose the wrong source, index, identifier, or search path.
- **Convention**: guidance was ambiguous, hidden at the decision point, or contradictory.
- **Scope**: the prompt or agent agenda caused avoidable clarification, drift, overreach, or underreach.
- **Execution**: tool errors, retries, excessive reads, poor result shaping, or restart instead of recovery.
- **Capture**: duplicate/misplaced notes, missed tasks, external-path pointers, weak boundaries, or incorrect social context.
- **Handoff**: missing verification, unclear closeout, poor commit boundaries, or absent continuation context.

## Success taxonomy

- **High-leverage context**: a note, index, identifier, or brief sharply reduced work.
- **Good narrowing**: scope or mode became explicit before expensive work.
- **Proportionate search**: targeted, shaped, or paginated retrieval avoided context overflow.
- **Resilient execution**: errors were diagnosed and resumed without discarding valid work.
- **Correct placement**: outputs followed vault schema, links, and source-of-truth rules.
- **Strong handoff**: coherent commits, verification, tasks, or a self-contained session brief preserved continuity.

## Evidence rules

Treat user corrections, tool actions/results, file paths, commits, final summaries, and explicit errors as primary process evidence. Treat assistant claims without a matching action/result as unverified.

One event can support several observations, but each observation gets one precise inference. Avoid long quotes and domain summaries.

## Fix versus optional suggestion

Call an improvement a **Fix** only when all are true:

1. Evidence shows a violated invariant or a recurring pattern.
2. The proposed target is the smallest durable control surface.
3. The user authorized the write or it is a normal in-scope audit update.
4. A concrete verification can show the change works and caused no transcript mutation.

Otherwise call it an **Optional suggestion** and name its promotion condition, such as a second occurrence, owner choice, missing source, or future-session evaluation.

Do not create a content note merely to store an audit observation. Keep process findings in the audit; promote only the control that changes future behavior.
