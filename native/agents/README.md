# Shared agent resources

This directory contains resources that are independent of any particular agent harness.

## Skills

`skills/` is the canonical, vendored skill collection. Harnesses consume it through the standard `~/.agents/skills` location. Pi and OpenCode both discover that location directly.

Third-party provenance is recorded in [`SOURCES.json`](SOURCES.json), with applicable licenses under [`licenses/`](licenses/). Vendored skills may be inspected and modified locally. Updating one is a deliberate source change: obtain the new upstream version, review the diff against the vendored copy, preserve local changes, update its provenance entry, and run the repository checks.

TWG's vendor-provided skills are deliberately excluded because their license prohibits retained and modified copies. Water Seven may contain independently authored TWG workflows based on user requirements, public documentation, and live CLI help, but not copies or derivatives of the vendor skills.

## Context

`CONTEXT.md` and `docs/` contain harness-neutral vocabulary and design material. Harness adapters decide which material, if any, belongs in an always-loaded context.
