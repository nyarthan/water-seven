# Agent Workflow: From Intent to Outcome

> Status: exploratory

This document develops a personal workflow for using Pi effectively. It starts from the simplest possible ideal and decomposes it only where doing so solves a real problem.

Subagents and delegated work were the original prompt for this exploration, but they are possible mechanisms rather than the goal. They should be considered only after the desired overall workflow is understood.

## Focus

### Near-term outcome

Improve day-to-day coding work in Pi by making intent, uncertainty, decisions, realization, and results coherent, legible, and robust.

This outcome is independently valuable even if Astral did not exist. The workflow should avoid preventing future integration, but it does not require Astral, the local development workflow, tmux integration, Ward, or a general multi-agent platform to deliver value.

### In scope

- The typed domain model for moving from expressed intent to an established result
- Adaptive structure based on uncertainty and blast radius
- Target briefs, gaps, decision authority, readiness, realization, and result evidence
- Pi interaction and persistence needed to make the workflow useful day to day
- A path for later delegation without making subagents the organizing concept

### Deferred relationships

- Astral ingestion, Direction, Governance, Abyss, and Flora integration
- `work` workspaces and multi-repository lifecycle integration
- tmux session or window orchestration
- Ward-backed isolation and capability enforcement
- A system-wide protocol shared by non-coding domains

These are future integration boundaries, not problems the first useful Pi workflow must solve.

## Ideal workflow

At the highest level:

1. The user tells the agent what they want to achieve.
2. The agent does the work and achieves the expected result.

This is intentionally oversimplified. It establishes the invariant we want to preserve while refining the workflow: every added phase, artifact, checkpoint, role, or agent must help turn intent into an achieved result. Structure that does not improve that transformation is overhead.

### Top-level input and output

- **Input:** the user’s expression of a desired outcome, which may be incomplete, ambiguous, or solution-shaped.
- **Output:** the expected result actually achieved—not merely activity performed or an answer claiming completion.

This immediately exposes two semantic gaps:

- The **alignment gap** between what the user says and what successful achievement actually means.
- The **achievement gap** between the agent’s actions and evidence that the desired outcome now holds.

### First minimal decomposition

A candidate first decomposition is:

1. **Establish the target** — turn the initial request into a sufficiently shared understanding of the desired outcome and how success can be recognized.
2. **Realize the target** — perform whatever investigation, decisions, changes, and coordination are needed to produce that outcome.
3. **Establish the result** — determine whether the outcome was achieved, surface remaining gaps, and communicate the resulting state.

This is not assumed to be a rigid linear pipeline. Discoveries during realization or validation may reveal that the target was misunderstood or incomplete, creating a feedback loop to an earlier activity.

This first-level decomposition matches the user’s mental model and is the current foundation for further refinement.

## 1. Establish the target

### Boundary

- **Input:** an initial expression of what the user wants to achieve, plus whatever conversational and environmental context is already available.
- **Output:** a sufficiently aligned target: the intended outcome, relevant boundaries, and a way to recognize success.

The output need not always be a formal specification. “Sufficiently aligned” should scale with ambiguity, consequence, and reversibility.

### Candidate decomposition

1. **Triage the request** — estimate ambiguity, blast radius, reversibility, and the cost of proceeding in the wrong direction.
2. **Interpret the request** — distinguish the desired outcome from suggested solutions, incidental wording, and implicit assumptions.
3. **Acquire orienting context** — inspect the user’s explanation and relevant sources to understand the problem space.
4. **Route consequential uncertainty** — determine who or what can legitimately resolve each gap, then investigate, decide collaboratively, escalate, or defer it as appropriate.
5. **Formulate the target** — state the outcome, boundaries, assumptions, and recognizable evidence of success at an appropriate level of detail.
6. **Assess readiness and align** — decide whether the target is ready for realization, ready only for bounded discovery, or blocked on user input. Obtain explicit confirmation when proceeding on a mistaken target would be costly; otherwise continue with the target kept legible and correctable.

### Decision authority and uncertainty routing

Not every unknown should become a question for the user, and not every question the user can answer is theirs to decide. For each consequential gap, the workflow should identify its resolution route:

- **Evidence-resolvable:** inspect code, documentation, history, external systems, or run a bounded experiment.
- **Agent-proposable:** develop options and a recommendation using available evidence.
- **User-owned:** collaborate with the user because they hold the relevant intent and decision authority.
- **Externally owned:** formulate the gap for the relevant decision maker, such as a product manager, architect, maintainer, or stakeholder.
- **Deferrable:** record an explicit assumption, exclusion, or later decision because it does not block the current slice.

Decision authority can be partial. In product work, for example, the user may own technical choices while a product manager owns behavior, scope, or priority. Establishing the target must preserve this boundary rather than silently converting missing product decisions into technical assumptions.

When escalating an externally owned gap, a useful output should include:

- The missing decision
- Why it matters now
- Concrete options or examples where possible
- Relevant trade-offs or consequences
- The agent’s recommendation, if evidence supports one
- What work is blocked and what can safely continue

### Target readiness

Establishing the target should return an explicit readiness state rather than assuming every request is immediately implementable:

- **Ready for realization:** the outcome and boundaries are clear enough to act with acceptable risk.
- **Ready for bounded discovery:** a named uncertainty must be reduced through a limited investigation, comparison, or vertical experiment.
- **Blocked on alignment:** a consequential choice depends on user intent, authority, or unavailable knowledge.

A readiness state is useful only when paired with the reason and the next action. It must not become ceremonial process.

### Target brief

For work that needs an explicit shared artifact, establishing the target produces a **Target Brief** containing:

1. Desired outcome
2. Scope or first vertical slice
3. Relevant system context
4. Recognizable success evidence
5. Constraints
6. Resolved decisions and their authority
7. Open gaps and their resolution routes
8. Explicit assumptions and exclusions
9. Target readiness and the next action

Simple, low-risk work may represent only the fields that carry information. The typed model should preserve semantic completeness without forcing an equally verbose presentation for every task.

### Optimization objective

Minimize the user effort, latency, and context gathered while keeping the risk of pursuing the wrong target acceptably low. This is not exhaustive requirements gathering. It is adaptive alignment.

The amount of structure should be selected using two primary signals:

| Uncertainty | Blast radius | Default behavior |
|---|---:|---|
| Low | Low | Act directly |
| High | Low | Run a small reversible experiment |
| Low | High | Confirm boundaries and approach |
| High | High | Perform bounded discovery, then explicitly align |

This model is accepted as a useful foundation. It is both diagnostic and active: the workflow should look for ways to reduce uncertainty and reduce blast radius. A narrow vertical slice can make progress safe even when the eventual system is broad.

### Representative scenario: cross-repository Markdown CMS

The user received an underdefined Jira ticket to implement a Markdown-based “CMS” that renders React through a component library. The work spanned multiple Git repositories and several packages. The requirements were unclear even to the user, and substantially less clear to the agent. The agent proceeded into broad implementation and produced a large, incoherent pull request.

This scenario combines several kinds of uncertainty:

- **Outcome uncertainty:** what user-facing capability the “CMS” must provide
- **Scope uncertainty:** which use cases, repositories, packages, and integrations belong to the first result
- **Contract uncertainty:** how Markdown content maps to React components and where validation, rendering, and ownership boundaries live
- **Decision uncertainty:** which architectural choices are preferences versus consequences of existing systems
- **Acceptance uncertainty:** what concrete examples would demonstrate that the system works

The failure was not simply missing information. Some requirements did not yet exist and could not be extracted from the user as facts. Establishing the target therefore needs to support **shaping an initially ambiguous outcome**, not just collecting context. Research, examples, option generation, and small exploratory work may be needed before a target becomes implementable.

Every major failure mode occurred in the resulting pull request: wrong architecture, excessive scope, inconsistent cross-repository changes, invented requirements, poor code quality, and an unreviewable volume of change. This suggests a systemic failure caused by premature broad implementation, not one isolated execution mistake. High uncertainty combined with high blast radius should trigger containment before implementation.

A key state the workflow must represent is:

> The target is not ready for broad implementation. The next useful work is bounded discovery that reduces a named uncertainty.

For this scenario, a sufficiently aligned target might require:

- A small number of representative content examples or user journeys
- An explicit first vertical slice
- A map of affected systems and their responsibilities
- Known constraints imposed by the repositories and component library
- The important unresolved choices, with options or recommendations
- Acceptance evidence for the first slice
- Agreement about what is deliberately excluded

### Executable domain model

The workflow should ultimately be represented in code with static types and runtime validation, rather than existing only as prose instructions in a skill or prompt. The typed model should make states, gaps, authority, readiness, evidence, and valid transitions explicit.

Prose remains useful for model judgment and interaction, but it should operate through the coded protocol. Static types cannot guarantee that a target is semantically correct; they can guarantee that the workflow represents what is known, what remains unresolved, who owns it, and why a transition is allowed.

The canonical domain vocabulary is maintained in [`CONTEXT.md`](../CONTEXT.md).

### Questions to refine

- Which parts of the target must always be made explicit?
- When is silent inference desirable, and when is confirmation necessary?
- How should the workflow distinguish an outcome from the user’s proposed implementation?
- What makes a misunderstanding consequential enough to interrupt the user?
- Should the target remain visible and revisable during realization?

## Relationship to existing projects

A review of Astral, the third brain, the local development workflow, Ward, and prior orchestration plans shows that this workflow is part of an existing architectural direction rather than an isolated Pi feature. A simplified, deliberately non-committal orientation is maintained in [`system-landscape.md`](./system-landscape.md).

### Astral

[`~/third-brain/projects/personal-automation-os.md`](~/third-brain/projects/personal-automation-os.md) defines Astral as a lifelong human-augmentation system and Pi-like coding agents as specialized execution workers. Several existing decisions directly constrain this workflow:

- Astral is a scoped delegate; autonomy belongs to explicit, revocable delegations.
- Process and outcome are coequal. Desired authorship, learning, collaboration, craft, or effort may be part of success.
- Meaningful delegation requires reversible handoff: preserve rationale, state, provenance, decisions, unresolved choices, and a path for the user to re-enter.
- Seams should be calibrated: routine low-risk support may be quiet, while provenance, uncertainty, authorship, and choice remain visible when stakes require them.
- Direction owns adopted goals and desired participation; Governance owns authority and delegation legitimacy; Infrastructure owns execution truth.
- Rich concepts such as goals, decisions, tasks, plans, actions, and outcomes belong to evolvable Shared Protocols or context-owned models, not Astral’s minimal kernel.
- Every consequential operation is durable, but each owning context retains authority over its state machine; a generic workflow runtime must not become domain truth.

The active Astral implementation at `~/dev/repos/nyarthan/astral` is intentionally focused on Abyss. Agent, task, action, and general workflow internals are explicitly parked. The legacy repository at `~/dev/old/nyarthan/astral` is prior art, not current design authority.

### Flora and Abyss

The third brain’s Knowledge Workflow Engine is now Flora, Astral’s epistemic context. Its separation of evidence, claims, accepted knowledge, uncertainty, and projections is relevant to acquiring context and establishing results, but Flora explicitly does not own task orchestration or agent execution.

Abyss owns source observation and lineage: what was observed, when, from where, and what material was retained. It does not decide truth or whether a work outcome was achieved. This reinforces the distinction between execution receipts, observed evidence, and an assessment that the target holds.

### Local development workflow

[`~/third-brain/projects/local-development-workflow.md`](~/third-brain/projects/local-development-workflow.md) already models development around a **Work Item**: one concrete goal, one flat multi-repository workspace, an explicit lifecycle, and a managed session. It establishes useful operational constraints:

- Multi-repository topology belongs to the work item rather than an arbitrary current repository.
- There is one active writer per work item; concurrent writers require separate delegated work items and explicit Git integration.
- Humans and agents should be able to enter, suspend, resume, and finish without reconstructing context from terminal state.
- Structural state is authoritative and typed; free-form `WORK.md` context is supplementary.

This is directly relevant to the failed cross-repository CMS scenario and to any later delegated implementation.

### Prior high-risk orchestration

The legacy Astral Brave-history plan is strong prior art for the high-uncertainty or high-blast-radius quadrant. It made goal, user stories, scope, non-goals, architectural decisions, slices, chunk outcomes, dependencies, file ownership, acceptance criteria, verification commands, independent judging, and result evidence explicit. It also enforced one slice at a time and blocked later slices on a failed independent verdict.

That process is too heavy to apply universally, but it demonstrates a concrete maximum-structure mode from which an adaptive workflow can scale down.

### Ward

Ward supplies an eventual execution-isolation and capability boundary for untrusted agent work. It can enforce filesystem, network, credential, and working-tree authority, but it should consume workflow decisions rather than own target, task, or outcome semantics.

### Architectural implication

A likely shape is a typed, durable agent-work protocol with Pi as one Surface and execution adapter. It should interoperate with work-item lifecycle, Governance, evidence/lineage, and sandboxing without collapsing those concerns into the Pi extension. Whether that protocol starts as Pi-local prior art, a standalone package, or a future Astral context remains undecided.

The number of potentially related pieces is itself creating cognitive overload. No placement decision should be forced while the system landscape is unclear. In particular, “work through Astral” is a false binary: Pi and tmux may remain the foreground experience while Astral participates as a continuity and augmentation substrate in the background.

## Original motivation

The exploration began with delegated or multi-agent work. “Subagent” is an implementation-flavoured term. **Delegated work** remains a broader provisional term for Pi arranging for a bounded part of an effort to be handled separately and returned to the main conversation.

## Why explore this?

The idea of subagents is appealing, but adding them without a clear purpose risks creating more orchestration, noise, cost, and uncertainty without making the work meaningfully better. Before choosing mechanics, we want to understand:

- Which recurring problems in the current workflow are worth solving?
- What would become possible, easier, faster, safer, or more reliable?
- Which responsibilities should remain with the main conversation?
- What would make delegation feel trustworthy rather than chaotic?

## Current understanding

Nothing below is a settled requirement.

- The main Pi conversation is valuable as a coherent place to establish intent and make decisions.
- Current usage tends to keep all work in one main thread and let the agent proceed within it.
- These sessions often feel overloaded and lack a clear structure. It is not yet clear whether the main cost is model performance, loss of direction, difficulty following the work, poor information retrieval, or some combination.
- A single context may be asked to explore, plan, implement, verify, and explain, potentially accumulating a lot of incidental information.
- Separate workers might offer fresh context, specialization, parallelism, or independent scrutiny.
- Delegation also introduces coordination costs: incomplete handoffs, duplicated work, conflicting edits, hidden assumptions, extra model usage, and results that still need evaluation.

## Earlier workflow hypothesis

### Context acquisition

An earlier discussion treated context acquisition as the first workflow chunk. In the higher-level decomposition above, it is better understood as an activity that may support **establishing the target**, **realizing the target**, or **establishing the result**, depending on why the information is needed.

Its purpose is to establish enough shared understanding to choose or evaluate a sound direction before substantial execution continues.

“Gather all relevant context” is an aspiration rather than a mechanically achievable stopping condition: relevance is discovered during investigation, and exhaustive gathering can itself become wasteful. A sharper working goal is therefore:

> Acquire sufficient relevant context, expose consequential uncertainty, and produce a shared basis for deciding what happens next.

Potential inputs include:

- The user’s task statement, intent, constraints, and unstated background
- Answers elicited from the user
- Repository code, tests, history, documentation, and current state
- Wikis, issue trackers, external documentation, APIs, and other systems
- Existing conventions, prior decisions, and organizational knowledge
- Findings and questions produced during investigation

The chunk should not merely accumulate raw material. Its returned result may need to distinguish:

- The interpreted goal and desired outcome
- Known constraints and boundaries
- Relevant findings with their sources
- Assumptions being made
- Uncertainties or contradictions that could change the direction
- Decisions needed from the user
- A recommendation about readiness to proceed

Open design questions include:

- What triggers a question to the user rather than independent investigation?
- How broad should initial discovery be before following a promising path?
- How are sources and confidence represented?
- What makes context “sufficient” for different kinds of tasks?
- Should context acquisition end in a durable artifact, a conversational checkpoint, or both?
- When later work reveals missing context, does the workflow return to this chunk or acquire it locally?

## Candidate outcomes to investigate

These are hypotheses, not a feature list.

### Preserve focus and situational awareness

Keep the main conversation centred on goals, decisions, and a legible overview while detailed work happens elsewhere. At any point, the user and agent should be able to explain what is being done, why it serves the goal, and what remains.

### Detect drift early

Make direction changes and questionable assumptions visible before substantial work accumulates in the wrong direction. Recovery should require correction, not reconstructing an entire messy session.

### Increase breadth

Investigate several areas or competing explanations without forcing them all through one context window.

### Gain independent scrutiny

Have a fresh perspective challenge a plan, review a change, or verify a claim without inheriting all of the main agent’s assumptions.

### Apply specialization

Use different instructions, capabilities, or models for meaningfully different kinds of work.

### Reduce waiting time

Perform genuinely independent work concurrently when the coordination overhead is lower than the time saved.

### Contain risk

Give delegated work narrower authority than the main agent—for example, research without modification—or isolate potentially conflicting work.

### Handle larger efforts

Coordinate work that is too broad for one uninterrupted agent loop while retaining a coherent overall direction.

## Scenarios to explore

Concrete scenarios will help reveal which outcomes actually matter.

- Understanding an unfamiliar repository before making a change
- Comparing multiple possible designs
- Tracing a bug with several plausible causes
- Implementing a change spanning unrelated parts of a repository
- Reviewing an implementation independently
- Running verification and interpreting failures
- Researching external APIs or documentation
- Maintaining progress across a long-running effort

For each relevant scenario, we should ask:

1. What is frustrating or unreliable today?
2. What would be delegated?
3. What context and authority would the delegate need?
4. What should come back to the main conversation?
5. Who decides whether the result is good enough?
6. What failure would be unacceptable?

## Important dimensions

These dimensions may turn out to matter more than the number of agents.

- **Initiative:** explicit user request, agent suggestion, or automatic delegation
- **Visibility:** silent work, progress summaries, or fully inspectable activity
- **Authority:** advise, read, execute commands, modify files, or make decisions
- **Independence:** shared assumptions versus intentionally fresh perspective
- **Coordination:** independent tasks, sequential handoffs, debate, review, or hierarchy
- **Lifetime:** one-shot task, reusable specialist, or persistent collaborator
- **Result shape:** answer, evidence, plan, patch, verdict, or unresolved questions
- **Trust:** how claims are sourced, checked, challenged, and accepted
- **Cost:** latency, model usage, attention, and orchestration complexity
- **Control:** cancellation, limits, approval boundaries, and recovery from failure
- **Orientation:** how both user and agent retain a shared overview of goals, current work, findings, decisions, and next steps
- **Drift detection:** when assumptions and direction are surfaced for correction instead of remaining implicit

## Open questions

- What structure is missing: phases, task boundaries, summaries, roles, artifacts, decision points, or something else?
- What is the smallest useful overview that would let the user detect a wrong direction early?
- When should the agent pause for alignment rather than continue autonomously?
- Is the main need context management, parallelism, specialization, independent review, autonomy, or something else?
- Should delegated work primarily advise the main agent, or should it act on the repository?
- Should the user address delegates directly, or should the main agent coordinate them?
- How much of delegated activity should be visible by default?
- What would make a delegated result trustworthy?
- What kinds of delegation would feel wasteful, distracting, or unsafe?
- How would we know the capability is successful after using it for a month?

## Emerging vocabulary

- **Decision authority:** who is entitled to choose among valid alternatives for a particular part of the target. Authority may be split between the user, external stakeholders, and established technical constraints.
- **Externally owned gap:** a consequential uncertainty whose answer depends on someone outside the current user-agent collaboration.
- **Blast radius:** the amount of the system and work product affected if the agent proceeds in the wrong direction. Cross-repository and cross-package changes generally have a larger blast radius than isolated, reversible edits.
- **Target readiness:** whether the current understanding supports broad realization, only bounded discovery, or requires user alignment first.
- **Bounded discovery:** limited work undertaken to reduce a named uncertainty without implicitly committing to a broad implementation.
- **Context acquisition:** the bounded activity of interpreting a task, gathering relevant information, and exposing consequential uncertainty before choosing a direction. Unlike “gather all context,” it aims for sufficiency rather than exhaustiveness.
- **Context source:** a person or system from which task-relevant information can be obtained, such as the user, repository, wiki, issue tracker, or external documentation.
- **Shared basis:** the structured understanding returned by context acquisition so that the user and agent can align on what is known, assumed, unresolved, and ready to happen next.
- **Main conversation:** the user-facing thread where intent, trade-offs, and overall progress remain coherent.
- **Delegated work:** a bounded part of the overall effort handled separately and returned to the main conversation.
- **Delegate:** the separate actor handling delegated work. This term does not yet imply a process, model, tool set, or lifetime.
- **Handoff:** the context, task, constraints, and expected result given to a delegate.
- **Returned result:** what the delegate gives back for use or evaluation in the main conversation.

## Decisions

### Use a three-part top-level workflow

The workflow is decomposed into **establish the target**, **realize the target**, and **establish the result**. These are activities with feedback loops, not a mandatory rigid pipeline. This is the accepted foundation for further exploration.

### Adapt structure to uncertainty and blast radius

The workflow uses uncertainty and blast radius to determine how much discovery and alignment is appropriate. Low-risk, well-understood work should not incur ceremonial process. High-uncertainty, high-blast-radius work should not proceed directly to broad implementation; it requires bounded discovery and explicit alignment. The workflow should also actively reduce blast radius through reversible experiments or narrow vertical slices.

### Route decisions to their legitimate owner

The agent should distinguish facts it can investigate, proposals it can develop, decisions the user owns, decisions external stakeholders own, and gaps that can safely be deferred. When the user owns a decision, the agent acts as a design partner. When authority lies elsewhere, it prepares a precise, informed escalation rather than inventing a requirement or treating the user as the decision maker.

### Make the workflow an executable domain model

The workflow’s source of truth should be code with static types and runtime validation, not prose buried in a skill or system prompt. Prompts may guide judgment, but typed states and transitions should provide the durable protocol and make invalid or incomplete workflow states harder to represent.

### Deliver independent value in Pi first

The near-term product is a coherent day-to-day coding workflow in Pi. Astral and the other related systems are future integrations rather than prerequisites. This scope reduction is deliberate: it lets the workflow prove its value without solving the complete personal operating system.

## Conversation notes

This section will capture observations and preferences as they emerge. Settled terminology and goals should be moved into the relevant sections above rather than left only as chronological notes.

### Initial motivation

The current pattern, carried over largely from OpenCode, is to remain in one main thread and let the agent do its work there. Those sessions often become overloaded and have no clear structure. There is a sense that this should work differently, but no assumed solution yet.

The practical failure is loss of overview for both the user and, presumably, the agent. The agent can proceed in a wrong direction for too long before the user notices, forcing avoidable backtracking. This makes situational awareness and early drift detection more central than subagents themselves.

### Reframing the workflow

The discussion briefly selected context acquisition as the first workflow chunk: gathering relevant context from the user, codebase, wikis, and other available sources. We then stepped back further. The governing workflow is now framed as moving from expressed intent to an actually achieved result. Context acquisition remains important, but it is a supporting activity rather than necessarily the first top-level phase.

The cross-repository Markdown CMS scenario shows that acquisition alone is insufficient: relevant requirements may not exist yet. The workflow must sometimes help create clarity through examples, alternatives, and bounded discovery rather than treating the user as a requirements database.

## Continuation handoff

### Current stopping point

The exploration is intentionally paused before decomposing **Realize the target**. No workflow implementation or subagent implementation has started.

The next proposed design step is to define the boundary and adaptive structure of realization. The motivating requirement is a small live orientation model that can always answer:

- What outcome are we pursuing?
- What slice are we working on?
- What is happening now, and why?
- What is complete, pending, or blocked?
- Which important decisions or assumptions changed?
- Did new information make the target unready again?

The central question is how to represent slices or work units without turning low-risk requests into project-management ceremony.

### Accepted so far

- The ideal is expressed intent becoming an actually achieved result.
- The top-level workflow is **establish the target → realize the target → establish the result**, with feedback loops.
- Structure adapts to uncertainty and blast radius.
- High-uncertainty, high-blast-radius work requires bounded discovery and explicit alignment before broad realization.
- Gaps are routed according to evidence and legitimate decision authority rather than all being asked of the user.
- Complex work can produce an explicit Target Brief and readiness state.
- The workflow should be an executable domain model with static types and runtime validation, not only prompt text.
- The near-term product should improve Pi independently; Astral and related systems are deferred integrations.

### Still undecided

- The decomposition and typed state of realization
- The decomposition and evidence model of result establishment
- Whether code merely records, guards, or strictly controls workflow transitions
- The exact static schemas and transition API
- Pi presentation, interaction, and persistence behavior
- When the workflow starts automatically versus explicitly
- How much state is visible by default
- Delegation and subagents
- Integration with Astral, `work`, tmux, and Ward

### Documents

- [`agent-workflow.md`](./agent-workflow.md) — main exploration, decisions, scenario, and prior art
- [`system-landscape.md`](./system-landscape.md) — orienting map of related pieces without architecture commitments
- [`../CONTEXT.md`](../CONTEXT.md) — canonical glossary for the emerging agent-workflow domain

### External material reviewed

- Legacy Astral at `~/dev/old/nyarthan/astral`, especially the Brave-history orchestration plan
- Active fresh Astral at `~/dev/repos/nyarthan/astral`, currently focused on Abyss
- Third-brain notes for Astral, Flora, Abyss, the local development workflow, Ward, and Pi

The external repositories and third brain were inspected read-only and had pre-existing local changes. They were not modified.
