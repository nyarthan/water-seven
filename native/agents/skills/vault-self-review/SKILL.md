---
name: vault-self-review
description: Review prior agent conversations as process traces and turn repeated friction or success patterns into verified vault improvements. Use when asked to audit agent sessions or transcripts, run a vault self-review, evaluate agent workflow quality, compare a new audit with a historical one, or improve vault conventions, navigation, templates, tasks, tools, or skills from conversation history.
---

# Vault Self-Review

Treat conversations as process traces. Produce fewer, better-supported improvements to the vault's operating system; leave domain facts in their existing canonical notes.

## Guardrails

- Keep transcript bodies immutable. A live audit may update wrapper `outcome` or `related` frontmatter only after the audit artifact verifies; a dry run changes no wrapper bytes.
- Treat wrapper frontmatter `outcome` as the review-status authority. Report any duplicated display field that disagrees with it.
- Extract process evidence: navigation choices, clarification, corrections, tool paths, retries, writes, commits, and handoffs. Do not re-extract conversation facts into content notes.
- Bound the sample before inspecting transcripts. Use 3-10 conversations for a normal batch; use one only for a pilot, regression fixture, or explicitly narrow request. Do not expand the sample silently.
- Read wrapper metadata first. For JSONL over 250 KB, use targeted search and the sampler before opening any raw event. Programmatic scanning is acceptable; linear model reading is the fallback for an unresolved trace, not the starting point.
- Label implemented, verified changes as **Fixes**. Label ideas that lack repetition, confidence, authority, or a safe verification path as **Optional suggestions**. Never present a suggestion as completed work.
- Finish with a dated audit artifact and recorded verification. A verbal summary alone is incomplete.

## Workflow

### 1. Load the control surfaces

Resolve the vault root, then read its conventions, conversation index, self-review project note, and conversation-wrapper template. Read the current audit note when extending an existing review cycle.

Completion criterion: identify the transcript location, audit-note location, valid note schema, review status source, and allowed write surfaces.

### 2. Freeze the sample

List wrappers from the conversation index without opening their JSONL bodies. Select a bounded set and state:

- included conversations and selection reason;
- exclusions and whether they are already reviewed, trivial, or out of scope;
- review mode: live batch, pilot, or dry run;
- maximum deep inspections permitted.

Prefer a diverse sample across session type, outcome, date, and apparent friction. Count a trivial session in scope but not against the deep-inspection budget.

Completion criterion: every candidate is included or excluded explicitly, and the sample cannot grow without revising the scope in the audit artifact.

### 3. Build bounded trace samples

Run the bundled sampler for each selected wrapper:

```bash
python3 <skill-dir>/scripts/trace_sample.py <vault-root>/<wrapper-path> --max-items 12 --max-chars 280
```

The sampler emits authoritative wrapper metadata, human-typed prompts, correction candidates, assistant process statements, write/edit targets, version-control actions, errors, and the final assistant text. It suppresses synthetic user events, attachments, and tool-result payloads.

Use targeted `rg -n` searches to answer questions raised by the sample. Search for exact prompt fragments, paths, tool names, error strings, commit commands, and correction wording. Inspect only the matched events. Open a full raw transcript only when it is at most 250 KB or when a documented contradiction remains unresolved after targeted inspection.

Maintain an evidence ledger with transcript, event line, observation, and process inference. Quote only the smallest fragment needed.

Completion criterion: each selected conversation has metadata plus evidence for its outcome, at least one success or an explicit `none observed`, and at least one friction item or an explicit `none observed`.

### 4. Classify process quality

Read [references/rubric.md](references/rubric.md), then classify each conversation as `good`, `mixed`, `bad`, or `trivial-skip`. Add a short qualifier such as `good-with-recovery-friction` only when evidence supports it.

Separate:

- **Success patterns** worth preserving;
- **Friction** attributable to prompting, navigation, conventions, tools, execution, or handoff;
- **Content facts**, which are out of scope unless they prove a process event such as a user correction.

Completion criterion: the classification follows the rubric and every finding cites ledger evidence.

### 5. Route findings into improvements

Group a pattern as cross-cutting only when it recurs in at least two sessions or a prior audit already establishes recurrence. Route each actionable finding to the smallest durable surface:

- navigation friction -> dashboard, MOC, or index;
- unclear invariant -> conventions or agent instructions;
- repeated output shape -> template;
- deferred concrete work -> task;
- repeated deterministic mechanics -> script or tool;
- stable multi-step agent practice -> skill.

For each **Fix**, record evidence, target, edit, and verification. Apply safe fixes within the user's requested scope. For each **Optional suggestion**, record the missing evidence, decision, or authority. Prefer no action over a speculative note or schema change.

Completion criterion: every actionable finding is implemented as a verified fix, logged as a concrete task, or explicitly retained as an optional suggestion with its promotion condition.

### 6. Write and verify the audit artifact

Copy [assets/audit-note-template.md](assets/audit-note-template.md) to the vault's audit-note location and fill every section. In a live audit, update allowed wrapper frontmatter and the project audit log only after the artifact is complete. In a dry run, keep results inside the fixture or requested output location.

Verify all of the following:

1. Every sampled conversation appears once in Scope and Classification.
2. Every finding has evidence and describes process rather than re-extracted domain knowledge.
3. Fixes match the actual diff and have a recorded check; suggestions are visibly separate.
4. Modified vault notes satisfy conventions, frontmatter, links, and available lint/tests.
5. Transcript bodies are byte-identical; dry runs leave all wrappers byte-identical.
6. The audit artifact exists at the reported path and contains the verification record.

If any check fails, mark the audit unverified and repair it before reporting completion.

Completion criterion: the audit artifact says `Verification: passed`, names the checks run, and the final response links the artifact and enumerates fixes separately from optional suggestions.

## Regression fixture

Use [references/dry-run-fixture.json](references/dry-run-fixture.json) to regression-test this skill against an already-reviewed conversation. Generate the dry-run findings before consulting the `historical_expectations` object, then compare classifications and process findings. Record matches, omissions, additions, and contradictions in [references/dry-run-comparison.md](references/dry-run-comparison.md). Never copy fixture expectations into the generated findings.
