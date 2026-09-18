---
name: resolve-design-friction
description: Resolve design friction during implementation. Use proactively when work accumulates special cases, repeated validation, expanding responsibilities, cross-boundary coordination, or a proposed fix would add a durable layer to preserve the current model.
---

# Resolve Design Friction

Treat friction as evidence about the model, not merely an obstacle to
implementation. Proceed through reversible friction. Pause on accumulating
pressure. Stop before durable sedimentation.

The goal is not to eliminate every branch or difficulty. Preserve essential
domain complexity while preventing accidental complexity from hardening around
an invalid assumption.

## 1. Establish the Current Model

Identify:

- the behavior the current work is meant to deliver;
- the hard invariants that must not change;
- the product promises that are valuable but negotiable; and
- the architectural and implementation assumptions intended to satisfy them.

Do not treat product promises or architectural choices as invariants merely
because an existing plan calls them decided.

This step is complete when invariants, negotiable promises, and provisional
design choices are explicitly distinguished.

## 2. Collect the Friction

List the discoveries that do not fit the expected design and the accommodations
already implemented or proposed. Include small signals; individually cheap
changes can reveal pressure when they share a cause.

Record unresolved signals in the project's existing task, plan, work log, or
active todo list. Do not create a new document for one local signal. If no work
artifact exists, retain the list for the next coherent progress or completion
report.

Look at both scales.

Implementation friction includes:

- branches, flags, nullable coupling, or states whose combinations require care;
- repeated validation, normalization, error translation, or policy checks;
- ordering assumptions, temporal coupling, and cache invalidation;
- rules duplicated across handlers or modules; and
- exceptions that bypass the normal control or data flow.

Architectural friction includes:

- a subsystem acquiring responsibilities outside its original purpose;
- multiple mechanisms needed to preserve one architectural promise;
- new services, protocols, coordinators, caches, supervisors, or lifecycle models;
- correctness that depends on coordination across an intended isolation boundary;
- required guarantees that available platform primitives cannot express; and
- a slice growing into a platform on which later slices must depend.

This step is complete when every known accommodation is recorded and related
signals are grouped by their shared cause.

## 3. Classify the Response

Classify friction by the cost of sedimentation, not by implementation size.

### Signal: Proceed and Report

Treat friction as a signal when the accommodation is local, cheap to remove,
does not change a boundary, and gives future code no reason to depend on a new
concept. Implement it, record it, and report it at the next coherent checkpoint.

A signal becomes pressure when it joins other findings with the same cause.

### Pressure: Pause at a Safe Checkpoint

Treat friction as pressure when findings share an architectural cause, a module
gains a new responsibility, rules spread across modules, or the next fix would
make later work depend more strongly on the questioned assumption.

Finish only the current safe, reversible unit. Do not add another accommodation
that deepens the commitment. Diagnose the shared cause and review the model with
the user before starting dependent work.

### Fault Line: Stop Before Implementation

Stop immediately when a proposed change would do any of the following:

- weaken, redefine, or leave a correctness or security invariant unresolved;
- add an architectural layer primarily to preserve the current architecture;
- introduce durable coordination across module, process, trust, or concurrency
  boundaries;
- change ownership, authority, trust, or lifecycle semantics;
- encode a workaround in a public API, protocol, persisted format, or migration;
- create a concept on which substantial future work will depend and which would
  be costly to remove; or
- make a broad change while the underlying model remains uncertain.

Any fault-line condition dominates the other classifications. Do not implement
the proposed change before the user chooses a direction.

## 4. Resolve the Cause

For pressure or a fault line, ask which assumption makes the accommodations
necessary. Separate unavoidable external or domain complexity from complexity
created by the model.

Search for the smallest structural change that removes the shared cause. Depending
on scale, reconsider:

- types and valid states;
- state transitions and operation phases;
- ownership and capabilities;
- transaction and concurrency boundaries;
- module responsibilities and dependency direction;
- data flow, protocols, and persistence models;
- product promises; and
- the global architecture.

Compare preserving the current design with at least one structural alternative.
For each option, state:

- which invariants and user value it preserves;
- which promise or assumption it changes;
- which friction it makes impossible or ordinary;
- where any remaining complexity lives;
- whether it removes complexity or merely moves and hides it; and
- the migration and deletion cost, including existing accommodations that become
  obsolete.

Prefer making problematic states or interactions impossible over repeatedly
detecting and repairing them. Do not generalize speculatively or redesign around
one isolated case.

This step is complete when every grouped friction item is eliminated by a
candidate design, accepted as essential complexity, or explicitly deferred with
its sedimentation risk stated.

## 5. Present the Decision

For pressure or a fault line, tell the user:

1. What the original model expected.
2. What implementation evidence contradicted it.
3. Which shared assumption causes the friction.
4. Why continuing now would be cheap, accumulating, or durable sedimentation.
5. The preserve-current-design option and its full cost.
6. The structural alternatives and your recommendation.
7. The concrete decision needed before work continues.

Do not disguise a redesign decision as a routine progress update. Do not present
only the workaround that keeps the current plan intact.

## 6. Reconcile After the Decision

After the user chooses a direction:

- update the project's plan, ADRs, domain language, and invariants where those
  artifacts exist;
- revise later slices that depended on the old assumption;
- remove superseded accommodations instead of retaining compatibility layers
  without a concrete requirement; and
- verify the resulting design against the original friction inventory.

Before declaring a coherent unit or slice complete, report every unresolved
friction signal grouped by its causing assumption and say whether it remains
isolated or has become pressure.

Reconciliation is complete when the implementation and planning artifacts
describe one design, obsolete sediment has been removed, and every unresolved
signal has been surfaced.
