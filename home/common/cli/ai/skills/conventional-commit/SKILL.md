---
name: conventional-commit
description: Generates a conventional commit message from staged changes or a described diff. Produces type, optional scope, subject, body (if needed), and breaking-change footer. Complements caveman-commit (style guide) — this one generates the message from scratch. Trigger with "generate commit", "create commit message", "commit this", "write commit for me", or "what should my commit say".
---

# Conventional Commit Generator

Generate a commit message from staged or described changes. Three phases.

---

## PHASE 1 — Gather changes

If running in a git repo, read:

```bash
git diff --staged --stat        # which files changed
git diff --staged               # actual diff
```

If the diff is too large, summarise the intent per changed file/module.

If no staged changes: ask the user to describe what they changed or paste the diff.

---

## PHASE 2 — Classify

### Type (pick one)

| Type | When |
|------|------|
| `feat` | New user-visible behaviour |
| `fix` | Bug or regression fix |
| `refactor` | Same observable behaviour, restructured internals |
| `perf` | Measurable performance improvement |
| `test` | Adding or fixing tests only |
| `chore` | Deps, tooling, config — no production code change |
| `docs` | Documentation only |
| `build` | Build system changes (webpack, Nix, Dockerfile) |
| `ci` | CI/CD pipeline changes |
| `style` | Formatting, whitespace — no logic change |
| `revert` | Reverts a previous commit |

### Scope (optional)

Infer from changed files. Examples: `api`, `auth`, `db`, `ui`, `nix`, `skills`. Skip if changes span too many areas.

### Breaking change

Mark `!` after type/scope and add `BREAKING CHANGE:` footer if any public API, DB schema, env var, or route changes incompatibly.

---

## PHASE 3 — Output

Produce the commit message as a code block, ready to paste:

```
<type>(<scope>): <imperative subject, ≤72 chars>

<body — only if the WHY is non-obvious, wrap at 72 chars>

BREAKING CHANGE: <description> (only if applicable)
Closes #<issue> (only if applicable)
```

**Subject rules:**
- Imperative mood: "add", "fix", "remove" — not "added"/"adds"
- No trailing period
- ≤50 chars ideal, hard cap 72

**Body rules:**
- Omit entirely when subject is self-explanatory
- Explain WHY, not what (the diff shows what)
- No "This commit does X"

Output only the code block. No explanation unless the user asks.
