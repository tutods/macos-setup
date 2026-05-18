## TypeScript Conventions

These conventions apply to all TypeScript projects on this machine.

### Strict mode

- `strict: true` always — no exceptions
- `noUncheckedIndexedAccess: true` — array access returns `T | undefined`
- `exactOptionalPropertyTypes: true` — `{ a?: string }` ≠ `{ a: string | undefined }`

### No escape hatches

- Never use `: any` or `as any` — use `unknown` + type narrowing
- `@ts-ignore` requires an explanatory comment on the same line
- Non-null assertion `!` only in test files or where invariant is documented in a comment

### Runtime validation

Prefer Zod for validating external data. Prioritise boundaries where correctness matters most:
- HTTP request bodies, query params, path params
- External API responses where the shape is not guaranteed

Not everything needs Zod — internal function calls between typed modules don't need runtime validation.

### Exhaustive switches

Discriminated union switches use `assertNever` so TypeScript errors at the missing branch:

```typescript
function assertNever(x: never): never {
  throw new Error(`Unhandled case: ${JSON.stringify(x)}`)
}
```

### Error handling

- `Result<T, E>` pattern for expected failures (not `throw`)
- `catch (e: unknown)` — never `catch (e: any)` or bare `catch`
- No empty catch blocks — at minimum log the error

### Package manager

Prefer `pnpm`. Check for a lock file before running any install command — use whatever the project already uses (`pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm). Never mix package managers in one project.
