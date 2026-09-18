# TODO

## Global Vim-style TUI navigation

Design and implement Vim behavior as a shared pi extension rather than baking key handling into individual components.

### Desired behavior

- Provide coherent normal and insert modes for the main editor.
- Use `j` and `k` to navigate lists in normal mode.
- Keep arrow-key navigation available.
- Use `i` to enter insert mode when a component has editable text.
- Use `Esc` to leave insert mode without clearing the text or changing the current selection.
- Preserve direct number-key selection in numbered lists.
- Show a restrained, native-looking mode indicator where useful.

### Architecture

- Put modal state and key interpretation in a dedicated global Vim extension.
- Expose reusable navigation helpers or an adapter for custom TUI components.
- Integrate `ask_user_question` with the shared system rather than adding local Vim mappings.
- Ensure native pi selectors and custom extension selectors behave consistently where pi's APIs permit it.
- Respect user-configured keybindings and restore any overridden bindings during extension shutdown.

### `ask_user_question` integration

In normal mode:

- `j` / `k` moves through suggested answers and the free-form option.
- Number keys immediately submit the corresponding suggested answer; selecting the free-form number focuses it.
- `i` selects the free-form option and enters insert mode.
- `Enter` selects the highlighted option.

In insert mode:

- Typing edits the free-form option inline.
- `Enter` submits the free-form answer.
- `Shift+Enter` inserts a newline.
- `Esc` returns to normal mode while preserving the text and leaving the free-form option selected.
