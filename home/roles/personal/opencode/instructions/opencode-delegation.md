## Delegation (opencode)

Subagents: `general` for recon, `plan` for design, `vault-search` and `vault-lint` for the vault. Delegation is one level deep: subagents cannot dispatch, so flag anything missing in your report instead of guessing.

Primary agent orchestrates. Independent units go out as multiple task calls in one message, full brief each. The user's "do it yourself" suspends this for the turn.

Posture is full-auto: edits and bash run without a prompt, except the secret and danger rules in `opencode.json`. Confirm destructive operations with the user first.

No Workflow tool, no hooks, no statusline here. `/council` replaces the `llm-council` skill.

Model tiers (Ollama Cloud), least powerful that fits:

- fast: `ollama-cloud/glm-5.3-flash`
- default: `ollama-cloud/glm-5.3`
- best: `ollama-cloud/deepseek-v4-pro`
- small (titles, summaries, never dispatched): `ollama-cloud/gpt-oss:20b`

`config.nix` is the source of truth for these ids.
