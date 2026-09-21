# Dispatch

Use this branch when the requested endpoint is running isolated agents, not supervising them through completion.

1. Split the work only where tasks can proceed independently. Identify shared files, ordering constraints, and decisions that would make parallel execution unsafe.
2. Write all prompts before launching any worktrees. Include the outcome, scope, constraints, relevant evidence, expected verification, and explicit non-goals.
3. Inspect `workmux add --help` and the active Workmux configuration. Choose the source branch, target repository, agent, and parent session deliberately.
4. Launch in the background. For cross-repository work, execute from the target repository and name that repository in the prompt.
5. Confirm every agent reached a running state. If launch or placement is ambiguous, diagnose it rather than creating duplicate worktrees.
6. Remove temporary prompt files after Workmux has consumed them.
7. Report each created handle, branch, repository, and assigned outcome.

Dispatch is complete once every requested agent is confirmed running. Do not begin implementing the delegated tasks in the coordinator's workspace.
