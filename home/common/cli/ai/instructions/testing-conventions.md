## Testing Conventions

### Stack

| Tool | Role |
|------|------|
| **Vitest** | Unit and integration tests |
| **React Testing Library** | Component tests — behavior, not implementation |
| **happy-dom** | DOM environment (faster than jsdom — prefer it) |
| **MSW** | HTTP mocking — intercept at network layer, not fetch mock |
| **faker.js** | Test data generation — no manual hardcoded mock objects |

No snapshot tests — banned (break on cosmetic changes, create false confidence).

### Vitest Config

Set `environment: 'happy-dom'` in `vitest.config.ts` — do not use `jsdom` unless a dependency explicitly requires it.

### File Location

Tests live in a top-level `tests/` directory, mirroring the source structure:

```
src/
└── user/
    └── user.service.ts
tests/
└── user/
    └── user.service.test.ts
```

Test files named `<source-file>.test.ts` — matching the module they test.

### When to Write Tests

**Do test:**
- Business logic with branching (conditions, edge cases)
- Data transformations
- Error paths — what happens when things fail
- Auth / permission logic
- Utility functions used in multiple places

**Do not test:**
- Framework behavior (React rendering lifecycle, ORM queries against a mock)
- Trivial getters/setters with no logic
- Implementation details — test behavior, not internals
- Third-party library code

### Test Structure

```typescript
describe('UserService', () => {
  it('returns user by id', async () => {
    // arrange
    // act
    // assert
  })

  it('throws NOT_FOUND when user does not exist', async () => {
    // ...
  })
})
```

Rules:
- Arrange / Act / Assert pattern — one assertion concept per test
- Test names describe behavior, not implementation: `'returns user by id'` not `'calls findById'`
- No `any` casts in test code — if types are wrong, fix the source
- No `console.log` left in tests
- Each test is independent — no shared mutable state between tests

### Coverage

No mandatory coverage threshold. Coverage is a proxy, not a goal. A test that exercises the critical path with real assertions is worth more than 10 tests that inflate coverage without catching bugs.
