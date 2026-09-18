# TUI conventions

## Icons

All extensions use Nerd Font **Octicons** (`oct-`) when an icon materially improves readability.

- Import semantic icons from `extensions/shared/icons.ts`.
- Do not embed raw icon glyphs in extension components.
- Add new glyphs to the shared module under semantic names rather than exposing icon-library names to consumers.
- Use icons sparingly. Prefer text, spacing, color, and typography for ordinary structure and selection.
- An icon must communicate status or an action; it must not be purely decorative.
- Keep text or color distinctions alongside icons where practical so meaning does not depend on the glyph alone.

This is a project-wide UI convention. New extensions should follow it, and existing extensions should migrate when touched.
