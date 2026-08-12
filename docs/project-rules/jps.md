## Project Rules — jps

### API response contract (ADR-0015)

No envelope. The HTTP status code is the sole success/error discriminator — the
body is either the data itself or the error itself:

```typescript
T                                              // single resource
{ items: T[], total: number }                  // list
{ code: string; message: string; details?: unknown }  // any non-2xx
```

`{ data, error }` was tried here and **deliberately dropped** — see ADR-0015.
Don't reintroduce it. Error codes are machine-readable strings
(`CUSTOMER_NOT_FOUND`, `VALIDATION_ERROR`), never numbers.

### Shared tooling config

Biome, TypeScript and Renovate config come from the `@tutods/*` packages in the
`lib` repo. Fix the package, not this repo's local copy — then check whether the
siblings need the same change.
