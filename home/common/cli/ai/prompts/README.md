# Prompt Templates

Load with `@home/common/cli/ai/prompts/<name>.md` in a conversation.

## Available prompts

### code-review
**Trigger:** `@prompts/code-review`
**When to use:** Reviewing PRs, examining new code, checking for security issues.
TypeScript/React review checklist — 8 sections (types, errors, RSC boundaries, security, performance, Biome, tests, breaking changes). Outputs severity-ranked table + verdict.

### explain-docs
**Trigger:** `@prompts/explain-docs`
**When to use:** Understanding a library, API, or framework feature for the first time.
Structured explainer: problem → mental model → minimal example → gotchas → when to use/avoid.

### pr-description
**Trigger:** `@prompts/pr-description`
**When to use:** Writing a pull request description from staged changes.
Reads `git diff` / `git log`, classifies the change type, and outputs Summary / Changes / Test Plan / Notes.

### debug
**Trigger:** `@prompts/debug`
**When to use:** Stuck on a bug or unexpected behavior — enforces structured diagnosis.
6-step flow: read full error → state delta → check recent changes → minimal repro → one hypothesis at a time → escalation path.

### new-feature
**Trigger:** `@prompts/new-feature`
**When to use:** Starting a non-trivial feature.
3-phase sub-agent orchestration: Explore (map existing patterns) → Plan (types + schema first) → Implement → parallel code-reviewer + test-analyzer → done checklist.
