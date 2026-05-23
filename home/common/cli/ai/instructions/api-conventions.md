## API Conventions

### Response Envelope

All API responses use this shape:

```typescript
// Success
{ data: T, error: null }

// Error
{ data: null, error: { code: string; message: string; details?: unknown } }
```

Never return raw data without the envelope. Never throw unhandled errors — always map to the error shape.

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

### Pagination

Prefer cursor-based pagination for large datasets:

```typescript
{ data: T[], nextCursor: string | null, hasMore: boolean }
```

Offset pagination only for small, non-real-time datasets where cursor is overkill.
