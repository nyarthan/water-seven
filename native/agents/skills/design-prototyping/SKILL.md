---
name: design-prototyping
description: Build a disposable artifact to answer a design question. Use when behavior, state, interaction, or visual structure needs concrete feedback before production implementation.
---

# Design Prototyping

A prototype is a disposable artifact that answers one named question. It is a phase of learning, not production implementation.

## Route by question

- For behavior, state transitions, or data shape, read [BEHAVIOR.md](BEHAVIOR.md).
- For visual structure or interaction, read [VISUAL.md](VISUAL.md).
- For another kind of uncertainty, choose the cheapest artifact that can falsify the current assumption.

## Shared contract

1. State the question, audience, expected feedback, and disposal or promotion decision before building.
2. Match fidelity to the uncertainty. Reuse real application context when it materially affects the answer; omit production concerns that cannot affect it.
3. Put a prototype for an existing application beside the relevant code and mark it unmistakably as a prototype. Put a standalone artifact in the OS temporary directory.
4. Make the artifact trivial for the intended reviewer to run or open.
5. Expose the behavior or differences the reviewer must judge; do not hide the question under polish.
6. Report what the prototype established and what remains uncertain.

Never commit, publish, deploy, or promote prototype code merely because it received positive feedback. Production implementation and cleanup begin only when requested. Temporary experiments made inside another phase must be removed before that phase ends.
