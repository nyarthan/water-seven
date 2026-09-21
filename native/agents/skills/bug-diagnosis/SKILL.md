---
name: bug-diagnosis
description: Diagnose bugs, failures, flakiness, and performance regressions through reproducible evidence and competing hypotheses. Use when something is broken, throwing, failing intermittently, or unexpectedly slow.
---

# Bug Diagnosis

Route by the requested endpoint. A diagnosis request ends with an evidenced cause or bounded uncertainty. A repair request continues from diagnosis into the smallest coherent fix and regression protection.

## 1. Characterize the symptom

State the observed behavior, expected behavior, affected environment, known onset, and evidence source. Confirm that any reproduction exercises the user's actual symptom rather than a nearby failure.

## 2. Build the tightest practical feedback loop

Prefer a focused failing test, script, request, browser flow, trace replay, benchmark, or minimal harness. Make it as deterministic, fast, and specific as practical. For intermittent failures, raise and measure the reproduction rate.

A runnable red/green signal is strongly preferred, not an absolute prerequisite. If reproduction is impossible, record what was attempted and continue with narrower evidence while labeling the resulting uncertainty.

## 3. Minimize and hypothesize

Remove irrelevant inputs and steps where practical. Generate multiple plausible, falsifiable hypotheses and rank them by existing evidence. Each hypothesis must predict an observation that can distinguish it from the alternatives.

## 4. Test discriminating evidence

Inspect history, state, boundaries, and runtime behavior. Change one diagnostic variable at a time. Use targeted instrumentation and tag temporary probes for cleanup. For performance, measure before changing code.

Revise the ranking when evidence disagrees. Do not turn the first plausible explanation into the conclusion.

## 5. Establish the result

For diagnosis, report the cause, evidence chain, ruled-out alternatives, confidence, and remaining gaps. Stop there unless repair was requested.

For repair, add a regression test at the highest useful seam when one exists, observe it fail, apply the fix, and observe both the focused signal and relevant surrounding checks pass. Remove diagnostic artifacts. If the architecture prevents useful regression coverage, report that design friction separately rather than adding a misleading test.
