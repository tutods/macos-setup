# Prompts & Local Skills

Reusable prompt templates and local AI skills. Load via `@` prefix in conversations.

## Prompts (`home/common/cli/ai/prompts/`)

| File | Trigger | Purpose |
|------|---------|---------|
| `code-review.md` | `@prompts/code-review` | TS/React PR review — 8-section checklist with severity-ranked output |
| `explain-docs.md` | `@prompts/explain-docs` | Library/API explainer — mental model, minimal example, gotchas |
| `pr-description.md` | `@prompts/pr-description` | PR description generator from `git diff` — Summary/Changes/Test Plan/Notes |

## Local skills (`home/common/cli/ai/skills/`)

Local skills are installed to `~/.agents/skills/` and symlinked to `~/.claude/skills/` on every deploy. No manifest entry needed — they deploy from the Nix store directly.

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `ts-strict-audit` | "strict audit", "audit types", "ts audit", "find any" | Scans tsconfig + source for strictness violations. Severity-ranked report with fix suggestions. |
| `conventional-commit` | "generate commit", "write commit for me", "commit this" | Generates a conventional commit message from staged diff. Complements caveman-commit (style). |
| `content-writer` | "write content", "blog post", "landing page" | PT-PT human-first content creation with SEO metadata output. |
| `llm-council` | "council", "run the council" | Multi-perspective decision framework: 5 advisors → peer review → Chairman recommendation. |

## Stack context files (`home/common/cli/ai/context/`)

@-mention these files at the start of a conversation to prime AI on project context:

| File | Use |
|------|-----|
| `@context/stack-personal` | Personal machine: TanStack Start, Next.js, Tailwind, shadcn/ui, Postgres, Drizzle/Prisma |
| `@context/stack-work` | Work machine: React/Next.js, MariaDB, NestJS, GCP |
| `@context/stack-nix-dotfiles` | This repo: module hierarchy, commands, conventions |
