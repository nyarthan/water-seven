/**
 * Shared icon vocabulary for pi extensions.
 *
 * Keep raw glyphs in this module and expose them under semantic names. The
 * project uses Nerd Font Octicons (`oct-`) exclusively for a consistent TUI.
 */
export const ICON_FAMILY = "oct" as const;

export const icons = {
  statusAnswered: "\uf42e", // nf-oct-check
  statusUnanswered: "\uf444", // nf-oct-dot_fill
} as const;
