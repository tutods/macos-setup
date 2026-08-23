## Delegation Contract

The harness ships with a default that says not to call the Agent tool unless the user asked for it. On this machine that default is replaced by this section. Subagents are the normal way to work here and need no request.

### Posture

The main thread is an orchestrator. It plans, dispatches, relays results and verifies them. It does not read, search or edit inline unless the work is a single already-known file or a one-line change.

Never dump a subagent's transcript. The user does not see agent output, so report what it found in your own words, with the `file:line` citations it returned.

### Delegate by default

| Work | Agent |
|------|-------|
| Recon, "where is X", "what calls Y", mapping a directory | `Explore`, or `caveman:cavecrew-investigator` when you want the compressed table |
| Anything touching more than one file | `general-purpose`, or `caveman:cavecrew-builder` for a mechanical 1-2 file edit |
| Reviewing a diff, a branch or a PR | `code-reviewer` |
| Reading or searching the Obsidian vault | `vault-search` |
| A scoped feature or fix that is already fully specified | `dev-lifecycle` |
| Designing an approach before implementing | `Plan` |

### Fan out

Two or more units of work with no shared state and no ordering between them go out as multiple Agent calls in a **single message**, so they run at the same time. Sequential dispatch of independent work is a bug.

Split before dispatching. "Understand the auth flow" is one agent; "understand auth, list the test helpers, find every caller of `getSession`" is three, in one message.

Give every agent the full brief it needs up front. A subagent cannot come back and ask a question.

### Always pass the model

`settings.nix` sets `opusplan`, so an agent dispatched without an explicit `model` runs on the expensive tier. Pass `model` on every dispatch, picked from the tier table in the next section. Mechanical fan-out on `opus` burns credits for nothing.

### Keep in the main thread

- Anything where the user has to choose. Subagents cannot ask, and guessing on their behalf is worse than a slower turn.
- Commits, pushes and pull requests. Those belong to the `open-pr` skill, which confirms with the user.
- `ui-iterate` and any other approve-per-step flow.
- Destructive operations, which need confirmation before they run.
- Trivial work where the dispatch costs more than the task.

### Escape hatch

"Do it yourself", "no agents", or "inline" from the user suspends this section for that turn. So does plan mode's own agent policy, which takes precedence over this one.
