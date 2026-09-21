---
name: test-driven-development
description: Develop behavior through red-green-refactor cycles. Use only when the user requests test-first work, TDD, or red-green-refactor—not merely because a task includes tests.
---

# Test-Driven Development

TDD advances one observable behavior at a time:

1. **Red:** add one test that fails for the intended reason.
2. **Green:** add only enough implementation to make that test pass.
3. **Refactor:** improve the design while keeping all tests green.

Repeat in thin vertical slices. Do not write a horizontal batch of speculative tests followed by a separate implementation batch.

## Choose the seam

Test through the highest useful public interface that observes the behavior without coupling to internals. Infer the seam from the requested behavior, existing interfaces, project tests, and architecture. Ask the user only when the choice is consequential or ambiguous; do not require ceremony for an obvious local seam.

When the interface itself is unsettled, use `codebase-design` before committing the test suite to it.

## Keep tests trustworthy

- Derive expected results from specifications, worked examples, or other independent sources—not by repeating the implementation's calculation.
- Prefer behavior and outcomes over calls, private state, and incidental ordering.
- Use real in-process collaborators where practical. Read [mocking.md](mocking.md) when an external dependency must be controlled.
- Give each test one behavioral reason to fail; multiple assertions are fine when they establish that one behavior.
- Follow the repository's fixture, naming, placement, and lifecycle conventions.

See [tests.md](tests.md) for examples of durable and implementation-coupled tests.

## Completion

For every slice, establish that the new test failed before implementation and passed afterward. At the end, run the broader checks justified by the changed surface and report the observed red/green evidence. Never weaken a test merely to admit the implementation.
