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
