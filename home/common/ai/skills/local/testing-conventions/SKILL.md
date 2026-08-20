---
name: testing-conventions
description: Testing conventions for this machine's projects, Vitest/Playwright stack, what to test and what not to, naming, and fixture patterns. Use when writing or reviewing tests, setting up a test runner, or deciding test coverage for a change.
---

## Testing Conventions

### Stack

| Tool | Role |
|------|------|
| **Vitest** | Unit and integration tests |
| **React Testing Library** | Component tests, behavior, not implementation |
| **happy-dom** | DOM environment (faster than jsdom, prefer it) |
| **MSW** | HTTP mocking, intercept at network layer, not fetch mock |
| **faker.js** | Test data generation, no manual hardcoded mock objects |

No snapshot tests, banned (break on cosmetic changes, create false confidence).

**Mock the network only.** MSW handlers, nothing else, no `vi.mock` of components, hooks, or the router. Exception: `vi.spyOn()` when asserting a function was called with specific arguments.

### Vitest Config

Set `environment: 'happy-dom'` in `vitest.config.ts`, do not use `jsdom` unless a dependency explicitly requires it.

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

Test files named `<source-file>.test.ts`, matching the module they test.

### When to Write Tests

**Do test:**
- Business logic with branching (conditions, edge cases)
- Data transformations
- Error paths, what happens when things fail
- Auth / permission logic
- Utility functions used in multiple places

**Do not test:**
- Framework behavior (React rendering lifecycle, ORM queries against a mock)
- Trivial getters/setters with no logic
- Implementation details, test behavior, not internals
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
- Arrange / Act / Assert pattern, one assertion concept per test
- Test names describe behavior, not implementation: `'returns user by id'` not `'calls findById'`
- No `any` casts in test code, if types are wrong, fix the source
- No `console.log` left in tests
- Each test is independent, no shared mutable state between tests

### User Interaction

Import `userEvent` directly, no setup call, for light suites. For interaction-heavy suites (typing into inputs, walking menus), hoist a `delay: null` instance at module scope instead, the default per-operation delay is real wall-clock time and dominates runtime:

```typescript
const user = userEvent.setup({ delay: null }); // module scope, above `describe`
await user.click(button);
```

If `delay: null` breaks a specific file (some overlay/popover libraries need a tick to settle before synchronous events fire), drop back to the direct import there, it's a per-file call, not global. Always `await` user events.

### Queries

Exact strings over regex when the text is known: `getByRole('button', { name: 'Add item' })`. Regex only when necessary, generic buttons, partial/dynamic text, case-insensitivity. Query by role/label, behavior, not implementation.

### `data-testid` Naming

- Always `kebab-case`, lowercase: `time-off-delete-button`, never `timeOffDeleteButton`.
- Structure: `[scope?]-[sub-scope?]-[element-type]`. Scope is the top-level feature/component, omitted when the component is already scoped by its file/context. Element-type describes what the element **is**, not what it does or its current state, `cancel-button`, never `disabled-button` or `ok-button-green`.
- Mandatory type suffix: `-button`, `-input`, `-textarea`, `-select`, `-menu`, `-modal`, `-container`, `-table`, `-row`, `-tab`, `-label`, `-link`, `-icon`, `-toggle`.
- Repeatable elements (list rows): tag the container **and** each repeatable element, with the discriminator (index/id/value) inside the testid string via template literal, `` `item-row-${id}` ``, not a shared testid indexed with `.nth()`.
- Third-party components that don't expose the attribute (embedded widgets, canvas-based libs): add it to a wrapper `<div>` the app controls, surrounding the component.
- One `data-testid` per element; values unique within the relevant test scope.

### Coverage

No mandatory coverage threshold. Coverage is a proxy, not a goal. A test that exercises the critical path with real assertions is worth more than 10 tests that inflate coverage without catching bugs.
