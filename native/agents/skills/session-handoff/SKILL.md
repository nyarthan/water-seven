---
name: session-handoff
description: Compact the current conversation into a temporary handoff for another agent or session.
disable-model-invocation: true
---

# Session Handoff

Create a concise Markdown handoff in the OS temporary directory, not the repository.

Include:

- the desired outcome and current phase;
- settled decisions and constraints;
- work completed and evidence established;
- current repository or runtime state that matters;
- unresolved questions, blockers, and risks;
- the next concrete steps; and
- applicable capabilities the receiving agent should load.

Reference existing plans, issues, commits, diffs, and documents by path or URL instead of copying them. Preserve the distinction between observations, assumptions, and user decisions.

Redact sensitive material already present in the conversation. Do not access new sensitive sources to enrich the handoff. Tailor the document to any stated purpose for the next session.

Completion means a fresh agent can continue without the transcript. Report the absolute path to the handoff file.
