# Behavioral prototypes

Use a behavioral prototype when the uncertainty concerns state, transitions, rules, data shape, or an interface contract.

- Isolate the questioned logic from presentation and infrastructure where practical.
- Render or print the relevant state after each action so changes are observable.
- Include the normal path, disputed edge cases, and actions that should be invalid.
- Prefer deterministic, in-memory fixtures unless persistence is itself the question.
- Use domain language in controls, scenarios, and output.

The artifact may be a reducer harness, state-machine explorer, focused route, script, notebook, or static HTML file. Choose based on the real question and project context rather than a fixed template.

Completion means the intended reviewer can exercise the disputed behavior and explain which model or rule should survive.
