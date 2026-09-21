---
name: design-friction-resolution
description: Detect and resolve design friction during implementation. Use when work accumulates special cases, repeated validation, expanding responsibilities, cross-seam coordination, or a proposed fix adds a durable layer to preserve the current model.
---

# Design-Friction Resolution

Treat implementation friction as evidence about the model. Proceed through isolated, reversible friction; pause when signals share a cause; stop before a workaround hardens into architecture.

The goal is not to eliminate essential domain complexity. It is to keep accidental complexity from accumulating around a false assumption.

## Establish the current model

Identify:

- the behavior being delivered;
- correctness, security, and domain invariants;
- valuable but negotiable product promises; and
- provisional architecture and implementation choices.

Do not promote a promise or design choice to an invariant merely because an earlier plan called it decided.

## Inventory the friction

Record every accommodation already made or proposed, including individually cheap ones. Group signals by shared cause.

Typical implementation signals include repeated branching, nullable coupling, normalization, validation, error translation, ordering assumptions, duplicated rules, or exceptions to normal flow.

Architectural signals include expanding ownership, new coordination across a seam, multiple mechanisms preserving one promise, platform limitations that cannot express a guarantee, or a feature slice turning into infrastructure for later work.

Use the project's existing work artifact when one exists. Do not create a new document for one local signal.

## Classify the response

### Signal — proceed and report

The accommodation is local, reversible, easy to remove, changes no seam, and introduces no concept future code will depend on. Implement it within the authorized task and report it at the next useful checkpoint.

A signal becomes pressure when other findings share its cause.

### Pressure — pause at a safe checkpoint

Several signals share an architectural cause, a module gains a new responsibility, a rule spreads, or the next workaround would make later work depend more strongly on the questioned assumption.

Finish only the current safe unit. Diagnose the shared cause and review the model with the user before dependent work continues.

### Fault line — stop before implementation

Stop when the proposed change would:

- weaken or redefine an invariant;
- add a durable layer mainly to preserve the current architecture;
- introduce coordination across ownership, trust, process, or concurrency seams;
- change authority, ownership, trust, or lifecycle semantics;
- encode a workaround in a public interface, protocol, persisted format, or migration; or
- create an expensive-to-remove concept while the underlying model remains uncertain.

A fault line dominates other classifications.

## Resolve the cause

For pressure or a fault line, identify the assumption that makes the accommodations necessary. Separate external or domain complexity from complexity created by the model.

Compare preserving the current design with at least one structural alternative. For each option state:

- invariants and user value preserved;
- promises or assumptions changed;
- friction removed or made ordinary;
- remaining complexity and where it lives;
- migration and deletion cost; and
- existing accommodations that become obsolete.

Prefer designs that make invalid states or interactions impossible. Do not generalize around one isolated signal.

## Present the decision

Explain the original expectation, contradicting implementation evidence, shared cause, sedimentation risk, preserve-current cost, alternatives, recommendation, and concrete decision needed. Do not disguise a redesign as a routine progress update or present only the workaround that keeps the current plan intact.

## Reconcile

After the user chooses a direction and implementation is authorized:

- update applicable plans, decisions, domain language, and invariants;
- revise dependent work;
- remove superseded accommodations rather than retaining compatibility without a requirement; and
- verify the result against the full friction inventory.

Completion means implementation and durable artifacts describe one design and every unresolved signal is reported with its causing assumption and current classification.
