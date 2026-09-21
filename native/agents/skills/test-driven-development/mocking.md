# Mocking external boundaries

Use a substitute when the test must control a dependency outside the behavior-owning system: a third-party API, clock, random source, process, or expensive infrastructure boundary. Prefer a realistic local implementation when one is cheap and deterministic.

Avoid mocking internal collaborators merely to observe calls. Such tests encode the current decomposition and fail during behavior-preserving refactors.

A useful substitute:

- implements the same narrow interface callers use;
- returns explicit domain-relevant outcomes;
- exposes only observations that cross the real seam;
- avoids conditional logic that recreates the production implementation; and
- is shared only when doing so makes tests clearer.

If a dependency is difficult to substitute without exposing many internals, reconsider the seam with `codebase-design` rather than widening the production interface solely for a mock.
