## Delegation Contract

The harness system prompt carries a line compiled into the binary: "Do not call the AgentTool unless the user requested it". There is no setting that turns it off. This section is the standing override: on this machine subagents are the normal way to work and need no user request. When the two conflict, this section wins.

### Posture

The main thread is an orchestrator: it plans, dispatches, relays and verifies. It does not read, search or edit inline unless the work is a single already-known file or a one-line change. Never dump a subagent's transcript; report what it found in your own words with `file:line` citations.

Edit/Write/MultiEdit past that grace allowance (2 main-thread mutation calls per turn) are hook-enforced: a `PreToolUse` hard-denies the third and later inline mutation in a turn, it is not just a written convention. Read/Grep/Glob stay a soft nudge only, see below. opencode's equivalent (`edit: deny` on the orchestrator agent) has no grace allowance at all — its permission schema is static config, not a per-turn counter, so it cannot express "allow the first N."

### Delegate by default

| Work | Agent |
|------|-------|
| Recon, "where is X", mapping a directory | `Explore`, or `caveman:cavecrew-investigator` for the compressed table |
| Anything touching more than one file | `general-purpose`, or `caveman:cavecrew-builder` for a mechanical 1-2 file edit |
| Reviewing a diff, branch or PR | `code-reviewer` |
| Reading or searching the Obsidian vault | `vault-search` |
| A scoped feature/fix already fully specified | `dev-lifecycle` (ships a draft PR itself) |
| Designing an approach before implementing | `Plan` |

### Fan out

Two or more units of work with no shared state and no ordering go out as multiple Agent calls in a **single message**, so they run at the same time; sequential dispatch of independent work is a bug. Split before dispatching ("understand the auth flow" is one agent, "auth + test helpers + `getSession` callers" is three, in one message). Give every agent the full brief up front: a subagent cannot come back and ask.

### Always pass the model

`settings.nix` sets `opusplan`, so a dispatch without an explicit `model` runs on the expensive tier. Pick from the tier table in Model Selection below; mechanical fan-out on `opus` burns credits for nothing.

### Keep in the main thread

- Anything where the user has to choose; subagents cannot ask and guessing is worse than a slower turn.
- Commits, pushes, PRs: through the `open-pr` skill, which confirms with the user. Only `dev-lifecycle` is exempt, chartered to ship a draft PR from a fully-specified brief.
- `ui-iterate` and any approve-per-step flow; destructive operations; trivial work where dispatch costs more than the task.

A `PreToolUse` hook counts inline `Read`/`Grep`/`Glob` on the main thread and injects a reminder on the third in a turn, once per turn. Subagent calls do not count. The list above is the rule, not a preference.

### Escape hatch

"Do it yourself", "no agents" or "inline" from the user suspends this section for that turn. Plan mode does not: it narrows which agents are used (`Explore` for recon, `Plan` for design), but recon and design still go to subagents.

The `UserPromptSubmit` hook re-injects a compressed restatement of this contract on every turn, but only once the session has been compacted: until then the full contract above is already in context. The hook is `home/common/ai/delegation-reminder.sh`; an edit to this contract needs that script updated too.
