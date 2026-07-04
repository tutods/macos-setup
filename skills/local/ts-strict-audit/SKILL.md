---
name: ts-strict-audit
description: TypeScript strict mode auditor. Scans tsconfig and source files for strictness violations, type escapes, and common unsafe patterns. Returns a severity-ranked report with suggested fixes. Trigger with "strict audit", "audit types", "ts audit", "find any", or "type safety check".
---

# TypeScript Strict Audit

Audit the current project for TypeScript strict mode violations and unsafe type patterns. Four phases in order. Do not skip.

---

## PHASE 1 — Config audit

Read `tsconfig.json` (and any `tsconfig.*.json` files). Check:

| Flag | Expected | Severity if missing/false |
|------|----------|---------------------------|
| `strict` | `true` | CRITICAL |
| `noImplicitAny` | `true` (or covered by `strict`) | CRITICAL |
| `strictNullChecks` | `true` (or covered by `strict`) | CRITICAL |
| `noUncheckedIndexedAccess` | `true` | MAJOR |
| `exactOptionalPropertyTypes` | `true` | MINOR |
| `noImplicitReturns` | `true` | MINOR |
| `noFallthroughCasesInSwitch` | `true` | MINOR |

Report any missing flags before continuing.

---

## PHASE 2 — Source scan

Search `.ts` and `.tsx` files (exclude `node_modules`, `dist`, `.next`, `build`). Find:

| Pattern | Grep/search | Severity |
|---------|-------------|----------|
| `as any` | `as any` | CRITICAL |
| `@ts-ignore` | `@ts-ignore` | CRITICAL |
| Explicit `: any` | `: any` | MAJOR |
| Non-null assertion | `!.` or `!;` | MAJOR |
| Double cast escape | `as unknown as` | MAJOR |
| Loose object spread | `{ ...obj }` where `obj: any` | MAJOR |
| `@ts-expect-error` without comment | `@ts-expect-error(?! .*\w)` | MINOR |

For each match: record file, line number, the offending code snippet.

---

## PHASE 3 — Boundary check

Look for system boundaries that should have runtime validation but may not:

- HTTP handlers (express/fastify/next/hono route handlers): is incoming `body`/`query`/`params` validated with Zod or similar before use?
- `process.env` access: is there a validated env schema (e.g. `t3-env`, `zod` parse of `process.env`)?
- External API responses: is the response parsed/validated or cast directly?

Flag unvalidated boundaries as MAJOR.

---

## PHASE 4 — Report

Output a ranked table:

```
## TypeScript Strict Audit

### Config issues
| Severity | Flag | Current | Recommended |
| ...

### Source violations
| Severity | File | Line | Pattern | Suggestion |
| ...

### Boundary gaps
| Severity | File | Boundary | Missing validation |
| ...

### Summary
- X CRITICAL, Y MAJOR, Z MINOR issues found
- Estimated effort: [< 1h / half-day / multi-day]
- Top 3 quick wins: [list]
```

Prioritise by severity descending. For each CRITICAL and MAJOR issue, add a one-line suggested fix.
