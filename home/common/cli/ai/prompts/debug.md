# Debug — Structured Flow

Use this prompt when stuck on a bug or unexpected behavior.

---

## Step 1 — Read the full error

Do not truncate, paraphrase, or assume. Read the complete stack trace or output.

Answer:
- What file and line does it originate from?
- What was the last successful operation before failure?

## Step 2 — State the delta

Write out explicitly:
- **Expected**: what should have happened
- **Actual**: what happened instead
- **When it started**: always or after a recent change?

## Step 3 — Check recent changes

```bash
git log --oneline -10
git diff HEAD~1
```

Is the bug correlated with any of these changes? Start there before diving deeper.

## Step 4 — Minimal reproduction

Reduce the failing case to the smallest input that still triggers the bug. Do not try to fix anything before you can reproduce it reliably.

## Step 5 — One hypothesis at a time

- Form one hypothesis
- Make one change
- Observe result
- Repeat

Do not make multiple changes at once. If something made it worse, revert before trying the next hypothesis.

## Step 6 — Stuck after 3 attempts?

Stop. Do these in order:
1. Re-read the original error from scratch — not your interpretation of it
2. Check the library/framework docs for the specific error message
3. Check git blame on the failing line — was it recently changed?
4. Step back and question the assumption that led to this approach

## Rules

- Never retry the same thing expecting a different result
- Never guess-and-check without a hypothesis
- If you added a workaround that "fixed" it without understanding why — that is not fixed
