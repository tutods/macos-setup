# PR Description Generator

Analyse the staged/committed changes and produce a pull request description.

## Step 1 — Gather context

Run these (or ask the user to run them):

```bash
git log main..HEAD --oneline       # commits on this branch
git diff main...HEAD --stat        # files changed
git diff main...HEAD               # full diff if needed
```

If the user provides a diff or commit list directly, use that.

## Step 2 — Classify the change

Pick the primary type:

| Type | When |
|------|------|
| `feat` | New behaviour, new feature, new API |
| `fix` | Bug fix, regression fix |
| `refactor` | Same behaviour, different structure |
| `perf` | Performance improvement |
| `chore` | Deps, tooling, config — no user-facing change |
| `docs` | Documentation only |
| `test` | Tests only |

Flag `BREAKING CHANGE` if any public API, DB schema, env var, or route changes in an incompatible way.

## Step 3 — Output the PR description

Use this exact structure:

```
## Summary

- [1–3 bullet points — what changed and why, not how]

## Changes

- [bullet per logical change group — file-level is too granular]

## Test plan

- [ ] [concrete step to verify the happy path]
- [ ] [edge case or regression to check]
- [ ] [manual or automated test reference]

## Notes

[Breaking changes, migration steps, deployment order requirements, known limitations — omit section if none]
```

Keep the Summary bullets tight — one idea per bullet. The reader should understand the purpose in under 10 seconds.
