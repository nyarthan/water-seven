# Agent Workflow

The language for coordinating work from a user’s expressed intent to an achieved and established result.

## Language

**Desired outcome**:
The state the user wants to bring about, independent of any initially suggested implementation.
_Avoid_: Task, prompt, request

**Target**:
A sufficiently aligned definition of the desired outcome, its boundaries, and how success can be recognized.
_Avoid_: Requirements, specification

**Target brief**:
The explicit shared representation of a target, including its scope, constraints, success evidence, decisions, assumptions, gaps, and readiness.
_Avoid_: Plan, context dump

**Target readiness**:
The current determination that a target is ready for realization, ready only for bounded discovery, or blocked on alignment.
_Avoid_: Status

**Decision authority**:
The person or established constraint entitled to choose among valid alternatives for part of a target.
_Avoid_: Knowledge, opinion

**Gap**:
A consequential uncertainty that must be routed to evidence, a proposal, a decision owner, or explicit deferral.
_Avoid_: Question, unknown

**Externally owned gap**:
A gap whose decision authority lies outside the current user-agent collaboration.
_Avoid_: User question

**Bounded discovery**:
Limited work that reduces a named gap without implicitly committing to broad realization.
_Avoid_: Research, exploration

**Blast radius**:
The amount of the system and work product affected if work proceeds in the wrong direction.
_Avoid_: Scope, complexity

**Realization**:
The work undertaken to make the target outcome true.
_Avoid_: Implementation, execution

**Result establishment**:
The determination of whether the target outcome was achieved, supported by appropriate evidence and remaining gaps.
_Avoid_: Verification, completion

**Shared basis**:
The structured understanding that allows the user and agent to align on what is known, assumed, unresolved, and ready to happen next.
_Avoid_: Context

**Delegated work**:
A bounded part of an effort handled separately and returned to the main conversation.
_Avoid_: Subagent
