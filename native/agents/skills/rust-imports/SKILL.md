---
name: rust-imports
description: Normalize Rust imports and qualified paths. Use when adding, editing, or reviewing Rust `use` declarations, module-qualified calls, trait scope, test imports, or name-resolution style.
---

# Rust imports

Optimize imports for **provenance**: a reader should see what a name is and where an operation comes
from without carrying repetitive root paths through the code.

## Rules

- Write one nested `use` tree per root in each scope. Let `rustfmt` lay it out.
- Import concrete types, traits, derive macros, and attribute macros directly. Keep conventional
  namespace families qualified, such as `io::Result`, `io::Error`, `fmt::Result`, and
  `fmt::Formatter`.
- Access every non-local free function and constant through its defining module. Import that module
  at the shortest stable boundary, then qualify the operation: `fs::read`, `random::fill`,
  `protocol::MAX_BYTES`.
- Treat an external crate root as an existing module namespace; `libc::flock` needs no redundant
  `use libc`. Keep raw FFI symbols—including types and constants—crate-qualified so their boundary
  remains visible.
- Use `self` in a tree when both a module namespace and its items are needed:
  `io::{self, Read}` or `protocol::{self, Message}`.
- Alias only to resolve a real collision or express an established domain name.
- Keep public re-exports separate from private imports; visibility and API intent outrank tree
  consolidation.
- Apply `cfg` to the narrowest complete import declaration. Do not hide unrelated portable imports
  behind a platform gate.
- In nested unit-test modules, use `use super::*` as the intentional test prelude. Imports from
  `std`, external crates, and non-parent modules still follow the normal rules.
- Use a fully qualified path for a one-off reference when introducing an import would obscure rather
  than shorten provenance. Switch to an imported namespace when the path repeats or dominates an
  expression.

## Review procedure

1. Inventory every `use`, `pub use`, qualified free-function call, qualified constant, and trait-
   provided method in the changed scope.
2. Classify each referenced item as module, type, trait, macro, free function, or constant.
3. Rewrite imports and call sites by the rules above; preserve visibility, `cfg`, and process-target
   boundaries.
4. Run the repository's relevant formatter, compiler, lints, and affected tests. Search the changed
   scope for glob imports and directly imported free functions.

The review is complete when every imported item has one classification, every non-local operation
outside the unit-test parent prelude retains module provenance at its use site, and the relevant
project checks pass without unused imports.
