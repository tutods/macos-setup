---
name: deep-review
description: Full-project review that produces an actionable markdown checklist file. Use when the user says "deep review", "review my entire project", "review my code and save it", "do a full review", or asks for a review with a checklist to track fixes. Detects the stack, loads the relevant best-practice skills, reviews in severity-ranked passes, writes docs/reviews/<date>.md with checkboxes, then optionally fixes items one at a time with verification after each.
---

# Deep Review

Review an entire project (or a scoped path) and produce a persistent, checkable report. Five phases, in order.

## Phase 0 — Scope

Confirm before reading any code (one message, skip anything already stated by the user):

1. **Target** — whole repo, one app in the monorepo, or a specific path?
2. **Mode** — review only, or review + fix afterwards?
3. **Focus** — everything, or weighted toward one area (types, UI consistency, security, performance)?

## Phase 1 — Detect stack, load skills

Read `package.json` (and workspace packages), lockfile, and config files. Then load the matching skills — **at most 3**, picked from what is actually in the project:

| Detected | Load |
|----------|------|
| TanStack Start / Router | `tanstack-start`, `tanstack-router` |
| NestJS | `nestjs-best-practices` |
| Sanity | `sanity` |
| Prisma | `prisma-client-api` |
| Tailwind / shadcn | `tailwind`, `shadcn` |
| Zod-heavy boundaries | `zod-validation` |
| Vitest | `vitest-testing` |

Also read the project `CLAUDE.md` / `docs/CONVENTIONS.md` — project conventions are review criteria, not suggestions.

## Phase 2 — Review passes

Work through each pass. **Every finding must cite `file:line` from code actually read in this session** — never report an issue from assumption or memory. If a pass finds nothing, say so and move on.

1. **TypeScript quality** — `any` escapes, missing strict flags, non-exhaustive switches, unvalidated boundaries (HTTP bodies, env vars, external API responses need Zod)
2. **Error handling** — empty/`any` catches, floating promises, swallowed errors behind fallbacks
3. **Framework boundaries** — server/client split, data fetching in the right layer, routing patterns
4. **Security** — authz checks on mutations, input validation before business logic, secrets in code or logs
5. **Conventions** — naming, file structure, export style, i18n usage vs. project CLAUDE.md
6. **Consistency** — duplicated components/utils, divergent patterns for the same problem (e.g. three button styles)
7. **Dependency hygiene** — unused deps, heavyweight packages with lighter native options

Severity: `[CRITICAL]` (bug, security hole, data loss) · `[MAJOR]` (violates a stated convention, real maintenance cost) · `[MINOR]` (style, polish).

## Phase 3 — Write the report

Save to `docs/reviews/<YYYY-MM-DD>-<scope>.md` (create the folder if missing):

```markdown
# Review — <scope> — <date>

## Summary
| Severity | Count |
|----------|-------|

## Checklist

### CRITICAL
- [ ] **[CRITICAL]** `path/file.ts:42` — problem — suggested fix — effort: S/M/L

### MAJOR
...

### MINOR
...
```

One line per finding. Effort is S (<15 min), M (<1 h), L (more).

## Phase 4 — Fix mode (only if requested)

Fix **one checklist item at a time**:

1. Fix the item with the smallest possible diff.
2. Run typecheck + lint + relevant tests.
3. Green → mark `- [x]` in the report file, move to the next item.
4. Red → stop, show the full error, do not start another item.

Never batch multiple checklist items into one edit round. Never touch files outside the item being fixed.

## Output

Final message: path to the report file + the top 5 findings in plain sentences.
