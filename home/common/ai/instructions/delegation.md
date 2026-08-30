## Delegation Contract

The harness system prompt carries a line compiled into the binary: "Do not call the AgentTool unless the user requested it". There is no setting or environment variable that turns it off. This section is the standing override: on this machine subagents are the normal way to work, and they need no user request. When the two conflict, this section wins.

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
| A scoped feature or fix that is already fully specified | `dev-lifecycle`, which ships a draft PR itself |
| Designing an approach before implementing | `Plan` |

### Fan out

Two or more units of work with no shared state and no ordering between them go out as multiple Agent calls in a **single message**, so they run at the same time. Sequential dispatch of independent work is a bug.

Split before dispatching. "Understand the auth flow" is one agent; "understand auth, list the test helpers, find every caller of `getSession`" is three, in one message.

Give every agent the full brief it needs up front. A subagent cannot come back and ask a question.

### Always pass the model

`settings.nix` sets `opusplan`, so an agent dispatched without an explicit `model` runs on the expensive tier. Pass `model` on every dispatch, picked from the tier table in the Model Selection section below. Mechanical fan-out on `opus` burns credits for nothing.

### Keep in the main thread

- Anything where the user has to choose. Subagents cannot ask, and guessing on their behalf is worse than a slower turn.
- Commits, pushes and pull requests you run yourself. Those go through the `open-pr` skill, which confirms with the user. The exception is `dev-lifecycle`, which is chartered to ship a **draft** PR from a fully-specified brief without that interactive step.
- `ui-iterate` and any other approve-per-step flow.
- Destructive operations, which need confirmation before they run.
- Trivial work where the dispatch costs more than the task.

A `PreToolUse` hook watches inline `Read`, `Grep` and `Glob` on the main thread. On the third such call in a turn it injects a reminder, once per turn. Subagent calls do not count. The list above is the rule, not a preference.

### Escape hatch

"Do it yourself", "no agents", or "inline" from the user suspends this section for that turn. Plan mode does not: it narrows which agents are used, `Explore` for recon and `Plan` for design, but recon and design still go to subagents.

The `UserPromptSubmit` hook injects a compressed restatement of this contract on every turn; its text lives in the `delegationReminder` binding in `home/common/ai/settings.nix`, so an edit to this contract needs that string updated too.
