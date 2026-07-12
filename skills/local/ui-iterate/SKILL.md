---
name: ui-iterate
description: Iterative UI refinement loop — one approved change at a time. Use when the user wants to refine, polish, or uniformize UI ("refine my UI", "uniform buttons", "improve the header/hero/cards", "the buttons are odd"), or wants to iterate on visual components with approval per step. Prevents batch changes that break unrelated components.
---

# UI Iterate

Refine UI components through an approve-then-apply loop. The user decides every change; nothing is applied speculatively.

## Hard rules

1. **One change per iteration.** Propose, get approval, apply, verify, then propose the next. Never bundle.
2. **Scope lock.** Touch only the files for the approved change. If the change genuinely requires editing another component, stop and ask first — do not "improve while you're there".
3. **Rejection = full revert.** If the user rejects an applied change, restore the touched files to their pre-change state (`git diff` to confirm clean) before proposing an alternative.
4. **Reuse before creating.** Extend shadcn/ui primitives via `className`/variants (CVA). No per-usage custom styles when a variant can express it. Tailwind classes only — no inline `style`.

## Step 1 — Inventory

Before proposing anything, map the target:

```bash
rg -l '<ComponentName' apps/frontend/src   # all usages
```

Present a short table: usage location → current variant/styles → inconsistency spotted. This is the shared ground truth for the session.

## Step 2 — Proposal queue

Turn the inventory into an ordered queue of discrete changes (most impactful first). For each item, present options with `AskUserQuestion`:

- 2–3 concrete options, recommended one first and labeled "(Recommended)"
- Each option includes a preview: the actual classes/variant code, or a short description of the visual result
- One question per aspect — don't mix "button shape" and "hover effect" in one question

## Step 3 — Apply + verify loop

For the approved option:

1. Apply with the smallest diff that realizes it.
2. Run typecheck + lint.
3. Tell the user what to look at in the running dev server and **wait for visual confirmation** before moving to the next queue item.
4. On "broken" feedback: run `git diff` first to isolate exactly what changed, show it, and offer revert before attempting a forward fix.

## Step 4 — Wrap up

When the queue is done (or the user stops), output a changelog:

- Accepted changes, one line each, with files touched
- Rejected/deferred items, so they can be revisited
- Suggest a commit (via the open-pr skill) — do not commit unasked
