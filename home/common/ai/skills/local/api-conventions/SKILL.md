---
name: api-conventions
description: HTTP API conventions for this machine's projects — no response envelope (status code is the discriminator), error shapes, pagination, validation at the edge, and GROQ query shaping for Sanity. Use when designing, implementing, or reviewing an HTTP API, REST endpoint, route handler, or CMS query.
---

## API Conventions

### Response Contract

No envelope. The HTTP status code is the sole success/error discriminator — the body is either the data itself or the error itself, never wrapped:

```typescript
// Success, single resource
T

// Success, list
{ items: T[], total: number }

// Success, no content (204)
// (empty body)

// Error (any non-2xx)
{ code: string; message: string; details?: unknown }
```

Error codes are machine-readable strings (`CUSTOMER_NOT_FOUND`, `VALIDATION_ERROR`), not numbers. Never wrap responses in `{ data, error }` — that envelope was tried and deliberately dropped. Never throw unhandled errors — always map to the error shape.

### HTTP Status Codes

| Status | When |
|--------|------|
| `200` | Successful GET / PUT / PATCH |
| `201` | Successful POST that created a resource |
| `204` | Successful DELETE (no body) |
| `400` | Validation error, malformed request |
| `401` | Not authenticated |
| `403` | Authenticated but not authorized |
| `404` | Resource not found |
| `409` | Conflict (duplicate, state mismatch) |
| `422` | Semantically invalid input (passes schema, fails business rule) |
| `500` | Unexpected server error |

Never return `200` with an error body. Never use `400` for auth failures.

### Environment Variables

Validate all env vars at app startup with Zod. Export a typed object — never access `process.env` directly in application code:

```typescript
import { z } from 'zod'

const env = z.object({
  DATABASE_URL: z.string().url(),
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z.enum(['development', 'production', 'test']),
}).parse(process.env)

export { env }
```

Rules:
- `env` object imported everywhere `process.env` would be used
- Missing or malformed vars crash at startup with a clear message — never silently undefined
- Secrets never have default values

### Input Validation

- Validate request bodies, query params, and path params with Zod at the route handler
- Reject early — validate before any business logic runs
- Return `400` with the Zod error details formatted as `{ code: "VALIDATION_ERROR", message: "...", details: zodError.issues }`

### CMS Queries (Sanity / GROQ)

Shape data in the query, not in TypeScript afterwards:

- Defaults via `coalesce()` in the projection
- Portable Text → string via `pt::text()` in the query
- No post-query `??` wrapper helpers

Wrong: `getSafePageData(result)` applying `??` to every field.
Right: `"title": coalesce(hero.title, "")` in the projection.

### Pagination

Offset pagination for typical admin/list endpoints — request `?page=1&pageSize=50`, respond:

```typescript
{ items: T[], total: number }
```

The client derives `page`/`totalPages` from its own request params plus `total` — don't echo them back.

Cursor-based pagination only for large or real-time datasets:

```typescript
{ items: T[], nextCursor: string | null, hasMore: boolean }
```
