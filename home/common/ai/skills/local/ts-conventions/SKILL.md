---
name: ts-conventions
description: TypeScript conventions for this machine's projects, strict mode settings, banned patterns (no `as` casting, no `any`), branded types, Zod at boundaries, naming, ESM package setup, and path aliases. Use when writing, reviewing, or refactoring TypeScript, choosing types, setting up a tsconfig, or scaffolding a new package.
---

## TypeScript Conventions

These conventions apply to all TypeScript projects on this machine.

### Strict mode

- `strict: true` always, no exceptions
- `noUncheckedIndexedAccess: true`, array access returns `T | undefined`
- `exactOptionalPropertyTypes: true`, `{ a?: string }` ≠ `{ a: string | undefined }`

### No escape hatches

- Never use `: any` or `as any`, use `unknown` + type narrowing
- `@ts-ignore` requires an explanatory comment on the same line
- Non-null assertion `!` only in test files or where invariant is documented in a comment

### Runtime validation

Prefer Zod for validating external data. Prioritise boundaries where correctness matters most:
- HTTP request bodies, query params, path params
- External API responses where the shape is not guaranteed

Not everything needs Zod, internal function calls between typed modules don't need runtime validation.

### Exhaustive switches

Discriminated union switches use `assertNever` so TypeScript errors at the missing branch:

```typescript
function assertNever(x: never): never {
  throw new Error(`Unhandled case: ${JSON.stringify(x)}`)
}
```

### Error handling

- `Result<T, E>` pattern for expected failures (not `throw`)
- `catch (e: unknown)`, never `catch (e: any)` or bare `catch`
- No empty catch blocks, at minimum log the error

### Style

- **Prefer array methods over `for...of`**, `map`/`filter`/`forEach` read better. Loops only where early exit or sequential `await` genuinely requires one.
  Wrong: `for (const item of items) { results.push(fn(item)) }` → Right: `const results = items.map(fn)`
- **No single-letter callback parameters.** Name them after the thing: `item`, `index`, `event`/`evt`, `error`. `i`, `e`, `err`, `res` are banned.
  Wrong: `items.map((i) => …)` → Right: `items.map((item) => …)`
- **Function declarations, not top-level arrow functions.** Arrows are for callbacks only (`useMemo`, `useCallback`, array methods, inline handlers).
  Wrong: `export const parseUser = () => {}` → Right: `export function parseUser() {}`

### Types over interfaces

Use `type` aliases, not `interface`. `interface X extends Y` becomes `type X = Y & { ... }`, intersection instead of declaration-merging inheritance.
Wrong: `interface User { id: number }` → Right: `type User = { id: number }`

### New packages

- **Every new Node package is ESM + TypeScript**, `"type": "module"` in `package.json` from the first commit. No CJS, no plain `.js` files.
- **Wire a path alias to the source root immediately**: no deep relative imports. Default convention is `@/*` → `src/`, but read the project's tsconfig rather than assuming; older repos may still use `~/*`.
  Wrong: `import x from "../../lib/utils"` → Right: `import x from "@/lib/utils"`, alias set in both tsconfig and the bundler.

### Package manager

Prefer `pnpm`. Check for a lock file before running any install command, use whatever the project already uses (`pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm). Never mix package managers in one project.

### Shared configs

Where a project consumes shared Biome/TypeScript/Renovate config from a package, fix the package rather than that repo's local copy, then check whether sibling repos need the same change, and say so. The consuming repo's own `CLAUDE.md` names which package.
