# Deepening modules

Use this reference when several shallow modules appear to represent one behavior. It assumes the vocabulary in [SKILL.md](SKILL.md).

## Classify dependencies

- **In-process:** computation or memory with no I/O. Keep it inside the module unless callers genuinely need it.
- **Local substitute:** infrastructure with a realistic local implementation, such as an in-memory filesystem or embedded database. Test the module with that implementation without exposing a new public seam.
- **Remote but owned:** another system under the same organization's control. Put a narrow port at the real process seam and keep transport in an adapter.
- **External:** a third-party system. Isolate its contract behind an adapter owned by the calling module.

An adapter seam earns its cost when behavior or environment genuinely varies across it. A test double alone does not justify exporting internal implementation structure.

## Replace shallowness

1. Name the behavior callers actually need.
2. Design the smallest interface that owns that behavior and its invariants.
3. Move coordination and policy behind the interface.
4. Test observable outcomes through the new interface.
5. Remove superseded pass-through modules, compatibility layers, and implementation-coupled tests unless a concrete compatibility requirement remains.

Deepening is complete when callers learn less, behavior changes in fewer places, and tests exercise the same interface as production callers. Moving complexity without reducing caller knowledge is not deepening.
