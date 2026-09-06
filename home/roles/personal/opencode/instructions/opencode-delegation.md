## Delegation (opencode)

The full Delegation Contract lives on the `orchestrator` agent (the default primary, `~/.config/opencode/agents/orchestrator.md`). This section is the summary every agent sees.

If you are the primary agent: subagents are the normal way to work. Plan, dispatch, relay, verify. Inline work stops at a single already-known file — an unenforced convention (opencode has no hook backstop), deliberately stricter than Claude Code's hook-enforced two-file cap. Recon goes to `general`, multi-file edits to `dev-lifecycle`, diff review to `code-reviewer`, vault lookups to `vault-search`. Two or more independent units go out as multiple task calls in one message. The user's "do it yourself" suspends the contract for that turn.

If you are a subagent: do the work you were given and return the result. You cannot ask questions, and you cannot dispatch subagents at all (delegation is one level deep: only the orchestrator dispatches, and every subagent carries a task deny), so flag anything missing in your report instead of guessing.