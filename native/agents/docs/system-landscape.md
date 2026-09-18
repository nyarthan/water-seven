# Personal Agent System Landscape

> Status: orienting map, not an architecture decision

This document exists to reduce overwhelm. It separates the roles currently represented by Astral, Pi, the local development workflow, tmux, Ward, the third brain, and the proposed agent-work protocol without requiring them to become one application or deciding their final boundaries.

## The false binary

“Do day-to-day work through Astral or not?” is probably the wrong first question.

A system can participate in work without owning the interaction surface. Day-to-day development could continue through Pi and tmux while Astral observes authorized activity, preserves continuity, supplies context, and receives outcomes. Astral-native surfaces may appear only where they add value.

The relevant questions are instead:

- Where does the user interact right now?
- Which system owns each kind of durable meaning?
- Which component executes work?
- Which component supplies isolation and authority enforcement?
- What information crosses each boundary, and for what purpose?

## Provisional role map

| Piece | Provisional role | Should not automatically become |
|---|---|---|
| **Astral** | Lifelong human-augmentation ecology and continuity across observation, knowledge, direction, governance, action, and reflection | The mandatory UI for every activity or one central agent loop |
| **Abyss** | Source observation, retained material, provenance, and lineage | Task manager, truth engine, or agent orchestrator |
| **Flora** | Evidence, claims, uncertainty, acceptance, and knowledge formation | Raw archive or execution runtime |
| **Third brain** | Current human/agent-readable knowledge surface and design memory; prototype of some future projections and workflows | Permanent universal runtime or database |
| **Pi** | Immediate conversational coding surface and agent runtime | Lifelong source of truth for goals, authority, or knowledge |
| **Agent-work protocol** | Typed coordination from desired outcome through realization to established result | Universal owner of every domain’s internal state |
| **Local development workflow (`work`)** | Work-item identity, multi-repository workspace, lifecycle, and development-session entry | Agent reasoning or knowledge authority |
| **tmux** | Reconstructable terminal runtime: sessions, windows, panes, and processes | Durable work-item or workflow authority |
| **Ward** | Isolation and capability enforcement for untrusted execution | Decider of desired outcomes or workflow semantics |
| **Models/agents** | Replaceable reasoning and execution participants operating under scoped context and authority | The whole system or independent source of terminal goals |

## A possible day-to-day path

This is one hypothesis, not a committed design:

```text
Jannis
  |
  v
work item + tmux
  |
  v
Pi conversation  <---- relevant context ---- Astral projections
  |
  v
agent-work protocol
  |
  +---- reasoning / delegated agents
  |
  +---- execution through local tools or Ward
  |
  v
repository and external outcomes
  |
  +---- operational result back to Pi
  |
  +---- authorized observations back to Astral
```

Under this shape:

- Pi remains the place where coding collaboration feels immediate.
- `work` and tmux provide the concrete place where development happens.
- The typed protocol keeps intent, gaps, decisions, progress, and results coherent.
- Ward can enforce execution boundaries when needed.
- Astral can provide continuity and receive observations without sitting in the foreground of every keystroke.
- None of these relationships requires Astral to be complete before the Pi workflow becomes useful.

## Separate planes

Thinking in planes may be easier than thinking in products.

### Interaction plane

Where the human sees, asks, decides, redirects, and receives results.

Current likely components: Pi, terminal, editor, future Astral surfaces.

### Work plane

Where a concrete effort has identity, files, repositories, processes, and lifecycle.

Current likely components: `work`, workspace manifests, tmux.

### Coordination plane

Where desired outcomes, gaps, decisions, slices, delegation, readiness, and result establishment are represented.

Candidate component: the typed agent-work protocol being explored.

### Execution plane

Where models, tools, commands, and delegated workers perform operations.

Current likely components: Pi agents and tools; future Ward-backed execution.

### Continuity plane

Where observations, provenance, knowledge, direction, authority history, and long-term learning survive individual sessions and replaceable tools.

Long-term component: Astral and its bounded contexts. Current partial surface: the third brain.

A component may participate in several planes, but each plane asks a different ownership question.

## What does not need deciding yet

- Whether Astral eventually has a primary conversational interface
- Whether Pi remains permanent or is replaced
- Whether the agent-work protocol lives first in the Pi repository or a standalone package
- Whether every Pi action is ingested into Astral
- Whether tmux remains the long-term runtime surface
- Whether Ward is required for all agents or only higher-risk execution
- The final Shared Protocol boundaries inside Astral

## Near-term orientation

The smallest coherent goal can remain:

> Improve day-to-day coding work in Pi by making intent, uncertainty, decisions, realization, and results legible and robust.

The design should preserve future interoperability with Astral, `work`, and Ward, but should not require solving the complete personal operating system first.

## Open questions

- Which day-to-day experience should improve first?
- What continuity should survive when a Pi session ends?
- Which information from work should Astral eventually observe, and which should remain intentionally opaque?
- Which decisions belong to a work item versus a lifelong Direction or Governance context?
- Where is the minimum useful boundary between immediate coordination and long-term knowledge?
