## Dependency Hygiene

### Before Adding Any Dependency

1. **Check if it already exists** — search `package.json` and existing imports first
2. **Check if native/existing solves it** — `Array`, `Date`, `URL`, `fetch`, Zod, TanStack Query cover a lot
3. **Check bundle impact** — use [bundlephobia.com](https://bundlephobia.com) or [pkg-size.dev](https://pkg-size.dev)
4. **Check maintenance** — last publish date, open issues, GitHub stars trend

### Flag These for Review

Always flag (comment to user) before adding:

| Package | Why flag | Prefer instead |
|---------|----------|---------------|
| `moment` | 67kb, deprecated | `date-fns` or `Temporal` (native) |
| `lodash` (full) | 71kb | Import specific functions or use native |
| Full icon libraries (`react-icons`, all icons) | Massive bundle | Import specific icon packages (`@heroicons/react`) |
| `axios` | Adds weight over fetch | Native `fetch` + wrapper, or `ky` |
| `uuid` | Overkill | `crypto.randomUUID()` (native, Node 16+) |
| `classnames` / `clsx` duplicate | Already likely present | Check if `clsx` or `cn` util already exists |
| Any dep with `>3 peer dep conflicts` | Version hell | Investigate before forcing install |

### Rules

- Never add a dependency to solve a problem solvable in <20 lines of code
- Never add a dev dependency that duplicates a tool already managed by Nix (formatters, linters)
- Run `pnpm audit` after adding deps with network access or auth-related functionality
- Lock major versions in `package.json` for packages with history of breaking changes (`"^"` is fine, `"*"` is not)
