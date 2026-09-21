---
name: pull-request-publication
description: Prepare, push, and publish the current branch as a draft pull request. Use when the user asks to open, create, or publish a PR. The capability excludes commits, assignments, review requests, approval, merge, and deployment.
---

# Pull-Request Publication

A clear publication request authorizes inspection of committed changes, pushing the current branch, and creating one **draft** pull request. It does not authorize committing dirty changes, modifying the implementation, assigning people, requesting reviewers, approving, merging, or deploying.

## Preconditions

1. Read applicable repository contribution and pull-request guidance.
2. Determine the intended base branch from the request, branch configuration, or repository convention.
3. Inspect status, commits, and the merge-base diff.
4. Stop and ask if the working tree is dirty, the base is ambiguous, the branch contains unrelated work, or publication would target an unexpected remote.

## Prepare

Derive the title and body from the actual diff, commit history, supplied specification, and verification evidence. Follow the repository's PR template when present. Be concise and state:

- the problem and outcome;
- material implementation decisions;
- verification actually performed; and
- known limitations or follow-up work.

Do not claim checks or user-visible results that were not observed.

## Publish

Push the current branch without force and create the PR in draft mode. Do not set assignees or reviewers. If a PR already exists, report it instead of creating a duplicate unless the user explicitly asks to update it.

Completion means the draft PR exists at the reported URL with the intended base and head branches. Publication does not include subsequent PR actions.
