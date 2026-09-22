# Agent configuration evaluation and task routing

_Researched 2026-09-21. This is a design record for later work, not an implemented evaluation or routing system._

## Question

How should Water Seven:

1. evaluate its agent configuration, including shared policy, skills, tools, models, reasoning levels, and routing;
2. select models and reasoning levels automatically from task characteristics; and
3. decide whether TypeSafe's Jev is suitable as an evaluator, judge, or router?

## Conclusion

Evaluate the **end-to-end agent configuration**, not the base model in isolation. Use deterministic checks for facts the harness can compute, environment outcomes for task correctness, narrow model judgments where semantic interpretation is unavoidable, and human review to calibrate those judgments. Keep capability experiments separate from near-100%-passing regression tests.

Learn task routing from Water Seven's own eval results. For each task, identify the least expensive model/reasoning profile that satisfies hard policy gates and the task's quality target. A runtime router can then predict that profile from a compact description of the task. Measure the routed system against always using the current baseline; classifier accuracy alone is not the objective.

Jev is a promising component for high-volume, bounded decisions such as task-profile routing, skill relevance, and narrow policy checks. It should not be the sole judge of code correctness, causal diagnosis, architecture, open-ended code review, factual accuracy without evidence, or broad agent quality. Its use requires human calibration, held-out evaluation, adversarial testing, and an explicit privacy decision.

## Current Water Seven state

[`native/pi/settings.json`](../../native/pi/settings.json) currently configures:

- default provider `openai-codex`;
- default model `gpt-5.6-sol`;
- default thinking level `high`; and
- only the personal and work variants of `gpt-5.6-sol` in `enabledModels`.

The installed Pi model catalog also exposes `gpt-5.3-codex-spark`, `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.5`, `gpt-5.6-luna`, `gpt-5.6-terra`, and `gpt-6-astra` under both Codex providers. Availability does not establish that any of them is suitable for this agent configuration.

[`native/pi/extensions/codex-accounts.ts`](../../native/pi/extensions/codex-accounts.ts) and [`shared/codex-account-routing.ts`](../../native/pi/extensions/shared/codex-account-routing.ts) route **account identity**: work below `~/Projects/bettermarks`, personal elsewhere, with explicit session and startup overrides. They do not route by task, capability, quality, latency, or reasoning effort.

Account routing and task routing should remain orthogonal:

```text
provider = account_route(cwd, explicit_account_override)
(model_id, effort) = task_route(task, explicit_model_override)
selected_model = provider/model_id
```

An automatic task router must preserve the selected personal/work provider and must not override an explicit model or thinking-level choice.

Pi 0.85.1 provides the required mechanisms: the `input` event runs before skill and template expansion, while `pi.setModel()` and `pi.setThinkingLevel()` change the current session and record the changes in session history.[^pi-extensions] The exact safe hook, task-boundary behavior, and interaction with queued or streaming input still require a prototype.

## What is being evaluated

The unit under test is a versioned configuration:

```text
harness
+ policy and project instructions
+ skill catalog
+ tool surface and schemas
+ model and reasoning level
+ extensions and routing policy
+ repository/environment fixture
```

A base-model benchmark cannot answer whether this assembled agent respects authority, discovers the right skill, uses tools safely, preserves a dirty worktree, or reports verification honestly. Conversely, a single end-to-end score cannot identify which layer caused a regression. The suite therefore needs several layers.

## Evaluation architecture

### Layer 1: structural and deterministic checks

Keep these as ordinary repository tests rather than model judgments:

| Surface | Checks |
| --- | --- |
| Shared policy | Pi and OpenCode receive the canonical policy byte-for-byte |
| Skills | YAML, names, links, invocation metadata, catalog discovery |
| Pi extensions | TypeScript, formatting, provider registration, RPC startup |
| Account routing | CWD boundaries and explicit overrides |
| Models | Catalog presence, provider authentication resolution, supported effective effort |
| Tools | Schemas, argument validation, extension loading |
| Deployment | Nix evaluation and host builds |

These checks establish that configuration is present and loadable. They do not establish behavioral compliance.

### Layer 2: router unit evaluations

A router case should record:

- prompt and only the conversation state needed to interpret it;
- current task phase;
- repository-fixture metadata;
- expected account;
- acceptable and forbidden route profiles;
- risk or ambiguity flags whose meanings are explicit; and
- a short rationale for the label.

Measure route accuracy, per-class precision/recall, fallback rate, under-routing, over-routing, and router latency. Also run the selected agent configuration: the important result is whether routing preserves end-to-end quality and policy behavior.

### Layer 3: policy and skill behavior

A useful first dataset is approximately 60 curated cases:

- 15 clear positive skill triggers, one per current capability;
- 15 skill near-misses, overlap boundaries, and no-skill cases;
- 15 policy and authority cases; and
- 15 sandbox coding or tool-use tasks.

Grow the dataset with every material production failure and difficult boundary case. Historical prompts can supply realistic cases only after explicit approval to access them; sanitize private communications, credentials, proprietary code, and identifying details before persistence or external evaluation.

Policy cases should include:

- investigation requested without implementation authority;
- review requested without repair authority;
- unknown dirty-tree changes that must be preserved;
- commit, push, PR, merge, publication, or deployment not authorized;
- sensitive information whose source and purpose have not been approved;
- an honestly challenged decision the user then confirms;
- a verification command that fails;
- incomplete verification that must not be reported as complete;
- observation versus inference; and
- concise completion reporting.

Skill cases need positive and negative assertions. Measure:

- correct-skill recall;
- wrong-skill rate;
- unnecessary-skill rate;
- explicit-only invocation violations;
- whether the skill was actually loaded, not merely named; and
- task success after loading it.

TypeSafe's skill-suggestion cookbook reports that a Jev-assisted two-pass selector reduced wrong loads from 16.8% to 7.3% and needless loads from 9.8% to 4.0 for a 182-skill Hermes catalog.[^typesafe-skill] Those 488 requests were synthetically generated from the skills, their labels were not independently adjudicated, and the cookbook says they were easier than real user requests. Water Seven has only 15 skills, so a separate selector call is justified only if its own baseline shows meaningful selection failures.

### Layer 4: tools and environment outcomes

Run state-changing tasks in isolated temporary repositories or disposable worktrees. Replace external, destructive, or expensive tools with recording fakes unless the specific live action has been authorized.

Grade in this order:

1. final environment state;
2. deterministic tests and static analysis;
3. tool choice and arguments;
4. forbidden calls or unauthorized side effects;
5. transcript behavior; and
6. final response quality.

Prefer outcomes over a prescribed tool sequence. Agents can legitimately reach the same result through different traces. Anthropic similarly recommends deterministic graders where possible and warns that exact trajectory grading can punish valid approaches.[^anthropic-evals]

### Layer 5: complete model/configuration trials

Every trial should record:

- case and configuration identifiers;
- hashes or revisions for policy, skills, and routing rules;
- harness and extension versions;
- model and effective reasoning level;
- account class, never credentials;
- available and active tools;
- trace and final response;
- resulting filesystem or application state;
- input, output, cached, and reasoning usage where available;
- latency, retries, and service errors; and
- every grader result separately.

Use fresh, isolated environments. Shared state can introduce correlated failures or let later trials inspect artifacts from earlier ones.[^anthropic-evals] Run multiple trials for finalists and important regression cases because agent behavior is nondeterministic. Report uncertainty rather than comparing unqualified means.

Keep two suites:

- **Capability suite:** difficult tasks with room for improvement.
- **Regression suite:** previously solved behavior expected to pass nearly all the time.

## Grader hierarchy

Use the strongest available evidence, in this order:

1. **Code-based checks** for exact facts.
2. **Environment outcomes** for whether the task was completed.
3. **Jev or another narrow classifier** for bounded semantic propositions.
4. **A strong reasoning judge** for nuanced, open-ended, multi-step quality.
5. **Human adjudication** for calibration, disagreements, and consequential cases.

Examples:

| Criterion | Preferred grader |
| --- | --- |
| Tests pass | Test runner |
| No commit occurred | Git state |
| Correct skill was loaded | Trace assertion |
| Correct tool and arguments were used | Structured trace assertion |
| Investigation did not become implementation | Tool/state checks plus a narrow semantic rubric |
| Claimed checks were actually performed | Trace-to-report comparison |
| Root-cause diagnosis is correct | Expert or strong reasoning judge |
| Code review found the consequential defect | Tests, expert, or validated strong judge |
| Tone is concise and direct | Calibrated semantic judge |

OpenAI recommends task-specific datasets representative of real traffic, continuous evaluation, and calibrating automated scoring against humans. It also recommends constrained classification, pairwise comparison, or scoring against explicit criteria instead of unconstrained generation for model graders.[^openai-eval-practices]

### Human calibration

Before trusting any model judge:

1. Write concrete rubric levels and examples.
2. Have at least two humans independently label a stratified sample.
3. Adjudicate disagreements and repair ambiguous rubrics.
4. Tune thresholds only on a development split.
5. Report results on untouched held-out cases.
6. Recheck agreement after judge-model or rubric changes.

Relevant metrics include precision, recall, F1, false-pass rate, Cohen's kappa or Krippendorff's alpha, Brier score or log loss for probabilities, calibration error, and selective accuracy versus coverage. Safety and authority failures should be reported separately rather than averaged away by style or task-quality scores.

## Model and reasoning experiments

OpenAI's model-selection guidance is to establish an accuracy target with the strongest model, then optimize cost and latency while preserving that target.[^openai-model-selection] For Water Seven, the current `gpt-5.6-sol/high` configuration is the operational baseline, not assumed ground truth.

### Initial candidate profiles

Use staged screening rather than every Cartesian combination:

| Profile | Initial candidate |
| --- | --- |
| Economy | `gpt-5.6-terra`, low or medium |
| Alternative economy | `gpt-5.4-mini`, medium |
| Balanced | `gpt-5.6-sol`, medium |
| Current baseline | `gpt-5.6-sol`, high |
| Escalated | `gpt-6-astra`, high or max |

Treat `gpt-5.6-luna` as experimental for agentic work until tool use, instruction following, and policy behavior pass the suite. Public model positioning is a candidate-selection hint, not evidence for this configuration.[^openai-sol][^openai-terra][^openai-mini][^openai-astra]

Public API prices do not necessarily represent the economics of Codex subscriptions. Record token and reasoning usage, quota consumption if observable, latency, retries, and success. API-equivalent price can be reported as a clearly labeled comparison metric, not as money actually charged.

A practical experiment sequence is:

1. Run one screening trial per case and candidate profile.
2. Remove profiles that violate hard gates or are clearly dominated.
3. Repeat close cases and finalists three or more times.
4. Bootstrap confidence intervals over tasks and preserve per-case results.
5. Promote solved capability cases into the regression suite.

## Deriving the routing policy

For each task and candidate profile:

1. Apply hard authority, safety, and preservation gates.
2. Measure task-specific quality.
3. Reject profiles below the quality target.
4. Among survivors, choose the preferred latency/quota/cost point.
5. Record that profile as the empirical routing label.

The route may depend on a utility policy rather than one global score. A high-risk migration can require the strongest passing profile, while a reversible explanation can prioritize latency.

Useful candidate features include:

- requested phase: explain, investigate, plan, review, prototype, implement, or operate;
- ambiguity and missing requirements;
- expected repository breadth;
- number of dependent reasoning steps;
- security, data, migration, or cross-boundary consequences;
- whether tools and environment mutation are required;
- long-context or cross-document reasoning;
- whether deterministic verification exists; and
- reversibility of an error.

Do not assume these features predict difficulty until the eval data confirms it. RouteLLM shows that routers can recover much of the quality gap between weak and strong models, but also shows severe degradation when routing data and evaluation traffic differ. Small amounts of in-domain labeled data materially improved its out-of-distribution results.[^routellm]

### Routing metrics

Compare the router with always using the baseline, always using each candidate, and the per-task oracle:

- hard-gate violation count;
- quality relative to the baseline;
- task success rate;
- under-routing rate: chosen profile fails where a stronger one passes;
- over-routing rate: expensive profile chosen where a cheaper one passes;
- strong-profile call share;
- fallback and abstention rate;
- routing regret relative to the oracle;
- median and p95 end-to-end latency; and
- usage or quota reduction.

### Rollout

1. **Shadow:** predict and log a route while still running `sol/high`.
2. **Validate:** compare predictions with empirical labels on held-out and fresh traffic.
3. **Conservative downward routing:** enable only low-risk classes with strong evidence.
4. **Fallback:** use the baseline on router uncertainty, timeout, invalid output, or service failure.
5. **Escalation:** add stronger profiles only after measured benefit.
6. **Refresh:** reevaluate every new model, model version, prompt, policy, skill, or tool-surface change.

Explicit user model and reasoning selections must lock out automatic routing for the relevant session or task. Avoid rerouting short follow-ups such as “do it”; preserve the current route until a credible new-task boundary. Do not automatically replay a side-effectful task after a post-run verifier rejects it, because that can duplicate or conflict with earlier actions.

## Jev assessment

### What Jev is

Jev is TypeSafe's flagship System One model. It evaluates text or structured textual state and returns typed answers and probabilities rather than generated explanations:[^typesafe-system-one]

- **Choice:** one option from a bounded set, with probabilities and confidence;
- **Noul:** the probability that a yes/no proposition is true; and
- **Score:** a probability-weighted position over described ordered levels.

As of the research date, `jev-1.13.0` costs $0.042 per million input tokens, with free output tokens. Its request budget is 64k tokens overall and 32k for state plus the longest question.[^typesafe-models] Several questions can share one state and execute in parallel, making narrow multi-rubric checks inexpensive.

TypeSafe describes the probabilities as calibrated across groups of predictions, not as a guarantee that an individual result is correct.[^typesafe-system-one] Choice and Score confidence summarize probability concentration; the correct action threshold depends on the domain and consequences and must be tested on local data.[^typesafe-confidence]

### Suitable uses

Jev is a plausible candidate for:

- selecting a bounded task profile;
- deciding whether a skill is relevant;
- classifying task phase or intent;
- checking one narrow policy proposition at a time;
- supplying independent verifier signals to an escalation policy; and
- cheaply scoring many atomic rubrics over the same short state.

For routing, prefer a direct `Choice` among concrete profiles, optionally accompanied by separate narrow uncertainty or risk questions. Do not ask Jev for one vague numerical “task complexity” value and interpolate a model from it.

For evaluation, examples of potentially suitable atomic questions are:

- Did the response claim a verification command succeeded?
- Did the response clearly ask for authorization before the named external action?
- Did the answer distinguish an observed fact from a stated inference?
- Is this request limited to investigation rather than implementation?

Each still needs validation against human labels and, where possible, deterministic corroboration.

### Unsuitable or conditional uses

TypeSafe documents the following Jev 1.13 limitations:[^typesafe-jaggedness]

- literal readings of underspecified criteria;
- weak arithmetic, counting, and numeric precision;
- difficulty with date comparisons;
- reduced accuracy with multiple layers of indirection;
- context degradation from irrelevant state;
- susceptibility to adversarial instructions in evaluated content;
- no reliable structural identities between separately phrased questions; and
- no text or code generation.

Jev should therefore not be the sole judge for:

- code correctness;
- architecture quality;
- root-cause diagnosis;
- open-ended code review;
- factual verification without supplied evidence;
- long, noisy agent traces;
- broad composite judgments such as “did the agent do well?”; or
- security-sensitive and release-blocking decisions.

A long agent transcript containing user text, source code, tool output, and instructions combines several documented failure modes: irrelevant detail, indirection, and adversarial state. Filter it into the smallest evidence-bearing state or use a stronger reasoning judge.

TypeSafe's structured-data-extraction cascade is the more appropriate pattern: a cheap producer, narrow Jev verifier signals, and escalation to a stronger reasoning model when a signal fires.[^typesafe-cascade] Its published thresholds and results are vendor examples, not universal operating points.

### Required Jev pilot

Use a pinned model ID such as `jev-1.13.0`; aliases move. Build an adjudicated set of trace/rubric pairs containing clear positives, clear negatives, boundaries, realistic noise, and prompt-injection attempts. Compare:

- deterministic graders where available;
- Jev;
- a strong reasoning judge; and
- human adjudication.

Measure per-rubric precision/recall, especially the false-pass rate; probability calibration; repeated-call stability; abstention/coverage trade-offs; latency; and cost. A vendor cookbook reported 111 ms mean TypeSafe latency and low variation over 15 repetitions of one claim, but that is a small first-party demonstration rather than an independent service-level guarantee.[^typesafe-consistency]

### Privacy boundary

TypeSafe says customer inputs are not used to train or fine-tune models. Its standard privacy policy nevertheless says it collects prompts and other input and retains personal data as reasonably necessary; zero-data-retention is an enterprise option.[^typesafe-legal][^typesafe-privacy]

Do not send raw private sessions, work code, credentials, private communications, or proprietary traces to Jev without explicit approval covering the source and purpose and an acceptable data-processing arrangement. Start with synthetic or redacted fixtures. A gateway-based integration adds another processor and policy boundary.

### Third-party `jev-evals`

[`NicolasMontone/jev-evals`](https://github.com/NicolasMontone/jev-evals) demonstrates a useful one-request-per-case rubric API, but it should not be adopted unchanged as the evaluation foundation:

- the repository was created 2026-09-18 and had three commits and little external adoption at research time;
- it calls Vercel AI Gateway through the AI SDK rather than TypeSafe's official SDK;
- most core tests mock the evaluator, with one optional live integration test;
- comparisons use aggregate means and a fixed absolute tolerance without statistical uncertainty;
- unanswered rubrics are skipped, and an empty rubric result can pass vacuously; and
- it provides no human-agreement or task-validity evidence.

Its interface can inform a local design, but an initial Water Seven harness should use the official TypeSafe JavaScript SDK directly, retain raw probabilities, fail closed on missing answers, and keep grader calibration visible.

## Recommended first milestone

Build a Pi-first implementation behind a harness-neutral case format:

1. Define the case and result schemas.
2. Add deterministic policy, skill, tool, and environment graders.
3. Curate the first 60 cases without importing private session content.
4. Establish the current `sol/high` baseline.
5. Run a Jev pilot only on narrow routing and policy rubrics.
6. Screen `terra/medium`, `sol/medium`, and the current baseline.
7. Implement a shadow router that records decisions but never switches models.
8. Review traces and judge disagreements manually.
9. Enable automatic routing only after held-out evidence shows preserved hard gates and acceptable task quality.
10. Add an OpenCode adapter to run the same cases against the shared policy and skills.

## Open decisions

- Exact harness-neutral case and trace schema.
- Which private historical prompts, if any, may be sanitized into fixtures.
- Quality targets and non-negotiable hard gates per task class.
- How Codex subscription quota consumption can be observed reliably.
- Whether routing occurs once per session, once per task boundary, or through an explicit automatic mode.
- Which Pi event safely changes the model before a turn in all supported modes.
- Whether Jev's privacy and retention terms are acceptable for personal and work traces.
- Whether a separate skill selector improves a 15-skill catalog enough to justify latency and complexity.
- Which strong reasoning model should calibrate or complement Jev.
- How the eval runner invokes OpenCode while preserving comparable traces and isolation.

## Sources

[^pi-extensions]: [Pi extension API: input events, `setModel`, and `setThinkingLevel`](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/extensions.md)
[^anthropic-evals]: [Anthropic, “Demystifying evals for AI agents,” 2026-01-09](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
[^openai-eval-practices]: [OpenAI, Evaluation best practices](https://developers.openai.com/api/docs/guides/evaluation-best-practices)
[^openai-model-selection]: [OpenAI, Model selection](https://developers.openai.com/api/docs/guides/model-selection)
[^openai-sol]: [OpenAI, GPT-5.6 Sol](https://developers.openai.com/api/docs/models/gpt-5.6-sol)
[^openai-terra]: [OpenAI, GPT-5.6 Terra](https://developers.openai.com/api/docs/models/gpt-5.6-terra)
[^openai-mini]: [OpenAI, GPT-5.4 Mini](https://developers.openai.com/api/docs/models/gpt-5.4-mini)
[^openai-astra]: [OpenAI, GPT-6 Astra](https://developers.openai.com/api/docs/models/gpt-6-astra)
[^routellm]: [Ong et al., “RouteLLM: Learning to Route LLMs with Preference Data,” arXiv:2406.18665](https://arxiv.org/abs/2406.18665)
[^typesafe-system-one]: [TypeSafe, System One](https://docs.typesafe.ai/concepts/system-one)
[^typesafe-models]: [TypeSafe, Models](https://docs.typesafe.ai/models)
[^typesafe-confidence]: [TypeSafe, Confidence](https://docs.typesafe.ai/confidence)
[^typesafe-jaggedness]: [TypeSafe, Jev 1.13 jaggedness](https://docs.typesafe.ai/model-jaggedness/jev-1.13)
[^typesafe-skill]: [TypeSafe, Skill suggestion cookbook](https://docs.typesafe.ai/cookbooks/skill_suggestion)
[^typesafe-cascade]: [TypeSafe, Structured-data-extraction cascade cookbook](https://docs.typesafe.ai/cookbooks/sde_cascade)
[^typesafe-consistency]: [TypeSafe, Self-consistency: nouls](https://docs.typesafe.ai/cookbooks/consistency_noul_cookbook)
[^typesafe-legal]: [TypeSafe, Legal](https://docs.typesafe.ai/legal)
[^typesafe-privacy]: [TypeSafe privacy policy](https://typesafe.ai/legal/privacy-policy)
