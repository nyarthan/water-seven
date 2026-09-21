---
name: architecture-assessment
description: Assess a codebase for evidenced architectural improvement opportunities. Use when the user asks for an architecture audit, structural improvement candidates, or places where module depth, locality, or testability can improve.
---

# Architecture Assessment

Read the `codebase-design` skill for the shared module, interface, depth, seam, adapter, leverage, and locality vocabulary.

## Bound the assessment

Honor a user-named area first. Otherwise inspect recent history and recurring friction to identify likely hotspots, state the proposed scope, and keep the assessment bounded. Read applicable project instructions, domain language, and durable architecture decisions before judging the code.

## Gather evidence

Trace representative behavior through interfaces, callers, tests, and dependencies. Look for:

- interfaces nearly as complex as their implementations;
- one concept spread across many callers or modules;
- pass-through modules that fail the deletion test;
- rules or coordination duplicated across seams;
- tests coupled to internals because no useful interface exists; and
- recurring changes that require shotgun edits.

Do not reward novelty or abstraction count. Existing code that is simple, local, and easy to change is not a problem merely because it lacks a named pattern.

## Present opportunities

For each candidate, report:

1. Evidence and affected paths.
2. The current interface or seam causing friction.
3. A structural direction, not a detailed implementation.
4. Expected leverage, locality, and testability gains.
5. Costs, migration risk, and confidence.

Rank candidates and recommend the strongest one. Use diagrams or a visual report only when they materially improve comparison or the user requests them.

Assessment ends with evidenced opportunities. Do not design the final interface or begin refactoring unless the user requests the next phase.
