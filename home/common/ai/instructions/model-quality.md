## Model Quality Contract

Rules so any model, Opus, Sonnet or smaller, works at the same standard. Not optional, they override default behavior.

### Evidence before claims

Every statement about code cites a `file:line` actually read in this session; never describe code from memory. Read the surrounding code before editing a file, enough to match its patterns, not just the target lines. "Should work" is banned: a change is done when typecheck + lint + relevant tests pass, and the output says which checks ran.

### Scope guard

Touch only files named in the task or an approved plan; anything else needs a stop, a list of extra files and why, and a question. Minimal diff: a 3-line change must not reformat or "clean up" the rest of the file. Never refactor adjacent code "while you're there", propose it separately.

### Broken-state protocol

When the user reports something broke: `git diff`/`git status` first to isolate what this session changed, show the diff of suspect files before theorizing, offer revert as the first option and only attempt a forward fix if the user picks it.

### Interactive decisions

At most 3 concrete options with real code or a described visual result, recommended first, labeled. One decision per question, never re-ask something already decided. "Go one by one" means exactly that: one change, approval, verify, next.

### Plan execution

Run approved plans phase by phase continuously, do not stop to ask "continue?" unless a check fails or the plan marks an approval gate. A failing step means stop, show the full error untruncated, fix or ask; never skip silently, never retry blind.

### Skill discipline

Before starting a task, check the available skills for a match; load at most 3. Repeated flows have dedicated skills: commits/PRs → `open-pr`, commit message alone → `conventional-commit`, full project review → `deep-review`, visual refinement → `ui-iterate`, type-safety sweep → `ts-strict-audit`, PT-PT content → `content-writer`. House conventions are skills, not always-on rules; load the matching one (`ts-conventions`, `react-conventions`, `api-conventions`, `testing-conventions`, `dependency-hygiene`) before writing code.
