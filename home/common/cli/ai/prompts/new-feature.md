# New Feature — Sub-Agent Orchestration Flow

Use this prompt when starting a non-trivial feature. Triggers a 3-phase sub-agent flow.

---

## Phase 1 — Explore (subagent)

Dispatch an `Explore` subagent to map the existing codebase before writing any code:

```
Spawn: Explore (subagent_type: Explore)
Goal: Map existing patterns in [affected area]
Find:
  - How similar features are structured (components, services, routes)
  - Naming conventions in use
  - Where types/schemas are defined
  - Existing utilities that can be reused
  - Test patterns for this area
Report: file paths + key patterns, under 300 words
```

Do not write any code until the Explore agent reports back.

## Phase 2 — Plan

Using the Explore output:
1. Define the layer breakdown: what is server-only, what is client, what is shared
2. List files to create and files to modify
3. Define types and Zod schemas first — before any implementation
4. Identify edge cases and error paths upfront

No code yet. Confirm the plan with the user if non-trivial.

## Phase 3 — Implement

Follow the plan. Use existing patterns discovered in Phase 1.

Rules during implementation:
- Folder structure: `index.tsx` + `partials/` for component sub-trees
- Zod schema at every boundary before writing logic
- No placeholder implementations — real code or explicit flag to user
- Stay within the feature scope — no opportunistic refactors

## Phase 4 — Parallel review (subagents, dispatch simultaneously)

After implementation, dispatch these two agents **in parallel**:

```
Agent 1 — code-reviewer (subagent_type: feature-dev:code-reviewer)
  Review the implementation for:
  - Correctness and type safety
  - Adherence to project conventions (react-conventions, api-conventions, ts-conventions)
  - Security issues (unvalidated input, missing auth checks, secrets in code)
  - Performance issues (N+1s, unnecessary re-renders, missing memoisation)

Agent 2 — test-analyzer (subagent_type: pr-review-toolkit:pr-test-analyzer)
  Review test coverage for:
  - Happy path covered
  - At least one error/edge case covered
  - No snapshot tests
  - Tests use RTL + happy-dom + MSW + faker.js per testing-conventions
```

Synthesize both reports. Apply critical and major issues before declaring done.

## Phase 5 — Done checklist

- [ ] `pnpm typecheck` passes
- [ ] `biome lint` passes
- [ ] Tests pass (`pnpm test`)
- [ ] No files changed outside the feature scope
- [ ] No commented-out code, no TODOs left unless flagged
- [ ] PR description generated (`@prompts/pr-description`)
