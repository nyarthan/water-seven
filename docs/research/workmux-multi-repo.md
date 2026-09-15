# Workmux multi-repository workflows

_Researched 2026-09-15 from the official site and its linked repository only. Source baseline: [`raine/workmux` commit `b2834949e356be08163e4e05c7944ab3e7a09380`](https://github.com/raine/workmux/tree/b2834949e356be08163e4e05c7944ab3e7a09380), whose package version is 0.1.262; the latest published release is [`v0.1.262`](https://github.com/raine/workmux/releases/tag/v0.1.262)._

## Conclusion

**No: Workmux has no durable “task” or “work item” object that owns worktrees from several repositories.** In Workmux, “task” is an informal description of a worktree/branch plus a multiplexer target and possibly an agent. Every lifecycle operation is rooted in exactly one Git repository. The official cross-project pattern is therefore **one prompt and one Workmux worktree per repository**, coordinated externally or by an agent skill—not one multi-repository Workmux task ([official worktree skill, `skills/worktree/SKILL.md`, lines 104–131](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/skills/worktree/SKILL.md#L104-L131)).

A coordinator can monitor agents across repositories, but that is orchestration over independent worktrees. The docs explicitly say that `send`, `capture`, `status`, `wait`, and `run` are cross-project, while `add`, `open`, `merge`, `remove`, and `close` remain repository-scoped ([Skills: cross-project communication](https://workmux.raine.dev/guide/skills/#cross-project-agent-communication)).

## Exact model

### Repository and configuration scope

- Configuration has two levels: global `~/.config/workmux/config.yaml` and per-repository `.workmux.yaml`; project settings override global settings. Only hook and file-operation lists can splice in `"<global>"`; settings such as `panes` replace the global value ([Configuration](https://workmux.raine.dev/guide/configuration/)).
- The relevant `Config` fields are singular: `main_branch`, `base_branch`, `worktree_dir`, `window_prefix`, `panes`, `layouts`, `windows`, `post_create`, `pre_merge`, `pre_remove`, `agent`, and lifecycle policy. There is no task ID, repository collection, peer-worktree collection, or dependency graph ([`src/config.rs`, `Config`](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/config.rs#L547-L630)).
- Each command builds one `WorkflowContext` containing one `execution_dir`, `main_worktree_root`, and `git_common_dir` ([`src/workflow/context.rs`](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/workflow/context.rs#L11-L135)). `workmux add` therefore selects its repository from the process working directory; the official skill says to run it with the target project as CWD ([`skills/workmux/SKILL.md`, lines 234–253](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/skills/workmux/SKILL.md#L234-L253)). There is no `--repo` or `-C` option.
- Nested `.workmux.yaml` files configure subdirectories of a **single monorepo**. They alter pane CWD, file-operation roots, and hook CWD; they do not create a cross-repository ownership model ([Monorepos](https://workmux.raine.dev/guide/monorepos/#nested-configuration)).

### Creation model

`workmux add <branch>` derives a handle, creates exactly one Git worktree at `<worktree_dir>/<handle>`, provisions it, and creates one managed window/session ([add: what happens](https://workmux.raine.dev/reference/commands/add/#what-happens)). Its internal `CreateArgs` has one branch and handle and receives its repository through `WorkflowContext`, not through a repository list ([`src/workflow/types.rs`, lines 11–56](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/workflow/types.rs#L11-L56)).

The “multi-worktree” modes (`--agent` repeated, `--count`, `--foreach`, or stdin) still generate only `WorktreeSpec { branch_name, agent, template_context }`; there is no repository field ([`src/template.rs`, lines 7–15 and 75–115](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/template.rs#L7-L15)). One creation plan loops over those specs and reconstructs each context from the same process CWD ([`src/command/add.rs`, lines 960–1124](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/command/add.rs#L960-L1124)). `--name`, `--target-name`, and `--parent-session` are also rejected for multi-worktree generation ([`src/command/add.rs`, lines 612–645](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/command/add.rs#L612-L645)).

### Persisted state

Workmux persists independent, repository-local and pane-local facts—not a work-item aggregate:

- In the selected repository’s local Git config: `branch.<branch>.workmux-base` ([`src/git/branch.rs`, lines 376–414](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/git/branch.rs#L376-L414)).
- Per handle in that repository: `workmux.worktree.<handle>.<key>`. Current keys include `mode`, `attachment`, `target-window`, `target-session`, `window-session`, and `window-token` ([`src/git/worktree.rs`, lines 322–425](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/git/worktree.rs#L322-L425); writes in [`src/workflow/create.rs`, lines 527–568](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/workflow/create.rs#L527-L568)).
- Under the XDG Workmux state directory, one JSON file per agent pane, keyed by multiplexer backend, instance, and pane ID. `AgentState` stores `workdir`, status/timestamps, pane/process identity, window/session names, and agent identity/session—not a task/group ID or peer list ([`src/state/types.rs`, lines 14–142](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/state/types.rs#L14-L142); [XDG locations](https://workmux.raine.dev/guide/configuration/#xdg-base-directory-support)).

## What can emulate a cross-repository work item

### 1. Preferred: fan out one Workmux worktree per repository

Use the same external work-item ID in each handle/branch, but invoke Workmux once per repository:

```bash
(cd /src/api && workmux add WI-123-api -b -P /tmp/WI-123-api.md)
(cd /src/web && workmux add WI-123-web -b -P /tmp/WI-123-web.md)
```

This is the official `/worktree` skill’s rule for work spanning repositories: separate prompt and worktree per repository, with each agent changing only its assigned worktree ([`skills/worktree/SKILL.md`, lines 104–131](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/skills/worktree/SKILL.md#L104-L131)). The `/coordinator` skill supplies fan-out/fan-in behavior—spawn, `wait`, `status`, `capture`, `send`, `run`, then merge sequentially ([Skills: coordinator](https://workmux.raine.dev/guide/skills/#coordinator)). The coordinator’s “tracked set” is conversational responsibility, not persisted Workmux ownership ([`skills/coordinator/SKILL.md`, lines 120–137](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/skills/coordinator/SKILL.md#L120-L137)).

Address active agents as `project:handle` when names collide:

```bash
workmux status api:WI-123-api web:WI-123-web --json
workmux wait api:WI-123-api web:WI-123-web --timeout 3600
workmux send api:WI-123-api "coordinate the schema version with web"
workmux capture web:WI-123-web -n 100
workmux run api:WI-123-api -- just test
```

Resolution first tries the local repository, then globally matches active agent worktree roots; `project:handle` filters by repository name or parent-directory alias and errors on ambiguity ([`src/workflow/agent_resolve.rs`, lines 10–97 and 117–219](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/workflow/agent_resolve.rs#L10-L97)).

### 2. Visual grouping: one tmux parent session, separate owned windows

In window mode, independent repository worktrees can be placed in one work-item-named tmux session. Give each managed window a unique repository name:

```bash
(cd /src/api && workmux add WI-123 -b -P /tmp/api.md \
  --parent-session WI-123 --target-name api)
(cd /src/web && workmux add WI-123 -b -P /tmp/web.md \
  --parent-session WI-123 --target-name web)
```

`--parent-session` is window-mode-only and creates the window inside the named session; the implementation creates that session if absent ([add options](https://workmux.raine.dev/reference/commands/add/#options); [`src/workflow/setup.rs`, lines 190–218](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/workflow/setup.rs#L190-L218)). This emulates one workspace **only in tmux layout**. The windows remain separately owned by different repositories and must be opened/merged/removed from their respective repository contexts.

Do not confuse this with `mode: session`: session mode means **one session per one worktree**. Its `windows` array creates several windows that all start in that same worktree, and session mode is tmux-only ([Session mode](https://workmux.raine.dev/guide/session-mode/#multiple-windows-per-session)). `panes`, named layouts, and `windows` arrange commands around one worktree; they cannot attach another Git worktree as a second owned root ([Configuration: panes/layouts/windows](https://workmux.raine.dev/guide/configuration/#panes)).

A global naming/layout convention can still make independent pieces recognizable:

```yaml
worktree_dir: "~/worktrees/{project}"
window_prefix: "{project}-"
panes:
  - command: <agent>
    focus: true
  - command: just test --watch
    split: horizontal
```

Only `~` and `{project}` are supported in `worktree_dir`; Workmux appends the handle. There is no `{task}` placeholder ([Configuration: basic options](https://workmux.raine.dev/guide/configuration/#basic-options)).

### 3. Hooks as a sidecar shim (possible, but not ownership)

The available lifecycle hooks are only `post_create`, `pre_merge`, and `pre_remove`. They run in the selected worktree/config directory and receive:

- all: `WM_HANDLE`, `WM_WORKTREE_PATH`, `WM_PROJECT_ROOT` (plus legacy `WORKMUX_HANDLE`);
- `post_create`: also `WM_CONFIG_DIR`;
- `pre_merge`: also `WM_BRANCH_NAME`, `WM_TARGET_BRANCH`.

See [Lifecycle hooks](https://workmux.raine.dev/guide/configuration/#lifecycle-hooks), [`src/workflow/setup.rs`, lines 54–90](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/workflow/setup.rs#L54-L90), [`src/workflow/merge.rs`, lines 210–246](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/workflow/merge.rs#L210-L246), and [`src/workflow/cleanup.rs`, lines 27–68](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/workflow/cleanup.rs#L27-L68). **Implementation caveat at the audited commit:** the web docs say every hook also gets `WM_CONFIG_DIR` and uses the nested config directory as CWD, but source sets `WM_CONFIG_DIR` only for `post_create`; `pre_merge` and `pre_remove` execute at the worktree root. A migration shim must follow the installed version’s behavior, not assume the broader documented contract.

A hook could call a custom script that creates/validates/removes a matching worktree in another repository, or updates an external work-item manifest. That is a custom transaction layered around Workmux: the second worktree gets no Workmux relationship, there is no `WM_TASK_ID`/peer list, no `post_merge` hook, and no cross-repository rollback. Prefer separate Workmux invocations plus an external coordinator.

File operations are not a substitute: copy/symlink sources are validated to remain under the selected config/repository root and destinations remain under its worktree ([`src/workflow/file_ops.rs`, lines 21–53 and 223–248](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/workflow/file_ops.rs#L21-L53)).

## Limitations relevant to migration

- **No aggregate lifecycle or atomicity.** `merge` resolves and merges one local worktree; `remove [name]...`, `--all`, and `--gone` operate in the current repository ([merge](https://workmux.raine.dev/reference/commands/merge/), [remove](https://workmux.raine.dev/reference/commands/remove/)). A two-repository finish can partially succeed and must be retried/reconciled by the caller. The coordinator guidance deliberately merges agents one at a time ([Skills](https://workmux.raine.dev/guide/skills/#fan-out--fan-in-pattern)).
- **Cross-project addressing depends on live tracked agents.** It is not a general repository registry. `workmux list --all` discovers only repositories represented by a tracked agent in the current multiplexer; repositories without tracked agents are undiscoverable ([list](https://workmux.raine.dev/reference/commands/list/#options)). `status --all` likewise covers reconciled agent state in one multiplexer instance ([status](https://workmux.raine.dev/reference/commands/status/)).
- **Names are not global work-item identities.** A plain handle is local-first; global duplicates require `project:handle`. Repository identity is derived from the main worktree directory name, so duplicate project basenames/aliases can still be ambiguous ([`src/workflow/agent_resolve.rs`](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/workflow/agent_resolve.rs#L117-L219)).
- **Layouts do not broaden Git scope.** Multi-window session layouts remain rooted in one worktree. `--parent-session`/`--target-name` cannot be combined with one command’s multi-worktree generation.
- **Hooks are per-worktree and pre-event-biased.** Failures abort that one operation; there is no built-in distributed ordering, compensation, or completion event after all repositories merge.
- **Sandbox access is narrower.** A sandboxed agent receives its current worktree read-write; other paths require user-controlled global `extra_mounts`, read-only by default ([Sandbox security model](https://workmux.raine.dev/guide/sandbox/#security-model), [extra mounts](https://workmux.raine.dev/guide/sandbox/features/#extra-mounts)). Separate per-repository agents preserve the intended boundary.

## Migration implications for a custom `work` CLI

1. **Do not replace a multi-repository work-item registry with Workmux state.** Retain a thin wrapper/manifest whose record is approximately `{work_item_id, [{repo_root, handle, branch, expected_path, mux_target, state}]}`. Workmux can own each leaf worktree; the wrapper must own membership, ordering, aggregate status, rollback, and “done”.
2. **Map leaf operations directly:** create → `workmux add`; attach/switch → `workmux open`; inspect path → `workmux path`; local finish → `workmux merge` or PR plus `workmux remove`; agent control → `status`/`wait`/`capture`/`send`/`run`. Invoke lifecycle commands with the corresponding repository as subprocess CWD.
3. **Standardize identity explicitly.** Put the external issue/work-item ID in each branch or handle and keep the repository in the wrapper record. Use `{project}` in `window_prefix`/`worktree_dir`, or unique `--target-name` values, rather than assuming equal handles imply membership.
4. **Use `--parent-session <work-item>` only as presentation.** It can preserve a custom CLI’s “one workspace per work item” UX, but must not become the source of truth.
5. **Adopt existing Git worktrees incrementally.** `workmux open <name>` opens a pre-existing worktree and creates its configured multiplexer layout, so migration need not recreate branches or move directories ([open](https://workmux.raine.dev/reference/commands/open/)). Configure new-worktree paths separately with `worktree_dir`.
6. **Keep orchestration failure-aware.** Create all prompt files first, then fan out one `add` per repository as the official skill does; record each success immediately. Merge/clean up sequentially and mark the external item complete only after every leaf succeeds.
7. **Use JSON as observation, not ownership.** `workmux list --json` gives leaf fields (`project`, `project_path`, `handle`, `branch`, `path`, mode/open/status data), and `status --all --json` gives reconciled agents. Neither returns a work-item grouping. Also, attached `workmux add` has no JSON receipt; source-only `add --headless --json` emits a single-worktree receipt but rejects prompts, multiplexer targets, layouts, multi-worktree options, and several other normal creation features ([`src/command/add.rs`, lines 216–328](https://github.com/raine/workmux/blob/b2834949e356be08163e4e05c7944ab3e7a09380/src/command/add.rs#L216-L328)). A wrapper should not parse human `add` output as its durable database.

**Recommended migration boundary:** replace custom per-repository worktree/tmux mechanics with Workmux, but retain the custom CLI as the multi-repository aggregate and transaction coordinator. Removing that layer would lose the exact capability in question.
