---
name: decision-grilling
description: Stress-test a plan, decision, or idea through a relentless structured interview. Use when the user asks to be grilled or wants assumptions, trade-offs, and unresolved decisions exposed before action.
---

# Decision Grilling

Map the subject as a **design tree**: each decision branches into the decisions that depend on it.

Work the tree in rounds. The **frontier** is every decision whose prerequisites are settled. In each round:

1. Ask the whole current frontier; do not ask a question that depends on another unanswered question in the same round.
2. Number every question and give a direct recommended answer.
3. Wait for the user's decisions.
4. Recompute the frontier from those answers.

Format each question as:

```markdown
❓ **Q1 — Title**: Question and relevant choices.

➡️ Recommended answer and why.
```

Find facts yourself. Inspect the environment or use an available research capability instead of asking the user for discoverable information. Ask the user for intent, preference, authority, and trade-off decisions.

Continue until the frontier is empty and nothing consequential remains silently assumed. Summarize the resulting shared understanding and ask the user to confirm it. The interview does not authorize implementation or documentation beyond temporary work needed to answer the current question.
