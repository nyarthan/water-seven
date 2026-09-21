---
name: domain-modeling
description: Build and sharpen a domain model through precise language, scenarios, boundaries, and invariants. Use when terminology is ambiguous, code and product language disagree, or a durable domain decision needs to be articulated.
---

# Domain Modeling

Treat domain modeling as a reasoning discipline first, not a required file layout.

## Sharpen the model

- Identify overloaded or synonymous terms and propose one precise canonical term for each concept.
- Distinguish concepts that share a casual name but differ in identity, ownership, lifecycle, or authority.
- Test definitions with concrete normal, edge, and failure scenarios.
- State invariants and valid transitions explicitly.
- Compare stated behavior with existing code and product behavior. Surface contradictions instead of choosing silently.
- Use the established domain language in names, examples, tests, and explanations once a term is settled.

## Respect boundaries

Do not turn implementation details into domain concepts merely because they appear in the code. Do not create an abstraction until scenarios demonstrate that the concept is real. Distinguish unavoidable domain complexity from accidental technical complexity.

## Persist only when authorized

Automatic invocation may inspect and apply existing domain knowledge, but it grants no permission to edit documentation. When the request includes maintaining the model:

1. Discover the repository's existing glossary, architecture-decision, and design-document conventions.
2. Update the smallest canonical artifact; do not impose `CONTEXT.md`, ADR directories, or a new schema on a repository that uses another convention.
3. Record a durable decision only when it reflects a consequential trade-off whose rationale future maintainers would otherwise lose.
4. Keep definitions, decisions, and implementation plans in their appropriate existing artifacts rather than combining them.

Completion means the relevant terms, scenarios, boundaries, and invariants are internally consistent; persistence is complete only when the authorized canonical artifacts agree with that model.
