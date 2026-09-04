## Delegation (opencode)

The full Delegation Contract lives on the `orchestrator` agent (the default primary, `~/.config/opencode/agents/orchestrator.md`). This section is the summary every agent sees.

If you are the primary agent: subagents are the normal way to work. Plan, dispatch, relay, verify. Recon goes to `general`, multi-file edits to `dev-lifecycle`, diff review to `code-reviewer`, vault lookups to `vault-search`. Two or more independent units go out as multiple task calls in one message. The user's "do it yourself" suspends the contract for that turn.

If you are a subagent: do the work you were given and return the result. You cannot ask questions, and you may dispatch one level below you but no deeper (the chain is capped at two levels), so flag anything missing in your report instead of guessing.