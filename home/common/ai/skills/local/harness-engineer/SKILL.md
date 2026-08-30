---
name: harness-engineer
description: Architectural design principles (reference/analysis, not a tool) for agent harnesses on long-running or multi-hour tasks — when to split planner/generator/evaluator roles, context resets vs compaction, sprint contracts, evaluator calibration, and when to strip scaffolding away. Use when designing or reviewing the architecture of a multi-agent harness or long-running autonomous build, e.g. deciding whether a task needs more than a single agent, or how to structure the roles if it does. For actually running multi-agent coordination (threaded messages, task dispatch, DAGs) use the `orchestration` skill/Orca tool instead — this skill is the design reference, not the execution mechanism. Based on Anthropic's "Effective harness design for long-running agents" (anthropic.com/engineering/harness-design-long-running-apps).
---

# Harness Engineer

A harness is orchestration around a model: it decomposes work, moves context
between agents, and verifies output. Every component encodes an assumption
about what the model cannot do alone — stress-test those assumptions, and
re-test them on every model release.

## When a harness earns its cost

- A full harness can be ~20× the cost of a solo run for the same brief, so it
  is worth it only when the task sits **beyond what the current model does
  reliably solo** (multi-hour builds, quality bars the model won't self-hold).
- Start solo. Add roles one at a time when traces show a concrete failure
  (premature completion, self-praised mediocre work, spec drift).
- On each new model, strip pieces that stopped being load-bearing: newer
  models sustain long agentic runs that previously required sprint
  decomposition and per-sprint evaluation.

## The three-role decomposition

| Role | Job | Calibration risk |
|------|-----|------------------|
| Planner | Expand a brief into a spec: deliverables and high-level design, not granular implementation detail | Over-specification cascades errors downstream |
| Generator | Implement one chunk at a time, self-check, commit to git as state | Trusting its own review — it will ship anyway |
| Evaluator | Exercise the running artifact like a user (e.g. Playwright MCP) against the contract | Finds real issues, then talks itself out of them |

Separating the agent doing the work from the agent judging it is the single
strongest lever: self-evaluation confidently praises mediocre output.

## Context management

- **Context anxiety is real**: models rush to finish as the window fills.
  Compaction shortens history but keeps the anxiety; a **context reset** with
  a structured handoff artifact gives a clean slate at the cost of that
  artifact having to carry all needed state.
- Handoffs go through **files with explicit contracts**, not conversation.
  Git is the generator's memory between sprints.

## Sprint contracts

Before implementing a chunk, generator and evaluator agree what "done" means:
testable, verifiable behaviors derived from the spec. Contracts bridge user
stories and implementation without freezing design details too early.

## Evaluator calibration

- Out-of-the-box LLM judges are poor QA; expect several tuning cycles.
- Convert subjective judgments into named, quantifiable criteria (e.g. design
  quality, originality, craft, functionality) and weight the dimensions the
  model is naturally weak on.
- Run generator↔evaluator as a GAN-style loop: concrete critiques, then the
  generator decides to refine (feedback trending better) or pivot (it isn't).
  5–15 iterations is a normal range for pushing distinctive output.

## Pitfalls

- Believing self-evaluation. It is the failure the evaluator role exists for.
- Over-specifying up front — planner errors multiply through every sprint.
- Skipping structured handoffs; prose summaries lose the state the next
  context needs.
- Treating verification as optional overhead; unverified sprints ship real
  bugs and silently dropped features.
- Keeping scaffolding out of inertia. Re-derive the harness from observed
  model behavior, not from what last year's model needed.
