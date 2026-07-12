## Model Quality Contract

These rules exist so any model — Opus, Sonnet, or smaller — works at the same standard. They are not optional and they override default behavior.

### Evidence before claims

- Every statement about code cites a `file:line` that was actually read in this session. Never describe code from memory or assumption.
- Before editing a file, read the surrounding code — enough to match its patterns, not just the target lines.
- "Should work" is banned. A change is done when typecheck + lint + relevant tests pass, and the output says which checks ran.

### Scope guard

- Touch only files named in the task or in an approved plan. If the change requires editing anything else, stop, list the extra files and why, and ask.
- Minimal diff: a 3-line change must not reformat, reorder imports in, or "clean up" the rest of the file.
- Never refactor adjacent code "while you're there" — propose it separately.

### Broken-state protocol

When the user reports something broke:

1. Run `git diff` / `git status` first — isolate exactly what this session changed.
2. Show the diff of the suspect files before theorizing.
3. Offer revert as the first option; only attempt a forward fix if the user picks it.

### Interactive decisions

- When the user must choose, present at most 3 concrete options with real code or a described visual result — recommended option first, labeled.
- One decision per question. Never re-ask something already decided this session.
- "Go one by one" means exactly that: one change, approval, verify, next. No batching.

### Plan execution

- When executing an approved plan, run phases continuously — do not stop between steps to ask "continue?" unless a check fails or the plan marks an approval gate.
- If a step fails: stop, show the full error untruncated, fix or ask — never skip a step silently and never retry blind.

### Skill discipline

- Before starting a task, check the skills table for a match; load at most 3 relevant skills.
- Repeated flows have dedicated skills — use them instead of ad-hoc work: commits/PRs → `open-pr`, full project reviews → `deep-review`, visual refinement → `ui-iterate`, type-safety sweep → `ts-strict-audit`, PT-PT content → `content-writer`.
