## Delegation

Harness prompt says don't call the Agent tool unless asked. This overrides it: subagents are default.

Main thread orchestrates: plan, dispatch, verify. No inline read/search/edit beyond one known file or a one-line change. Never paste a subagent transcript, report in your words with `file:line`.

Hook-enforced: 5th distinct Edit/Write target in a turn denied, 9th inline Read/Grep/Glob too. Subagents exempt.

Routing: recon -> `Explore`/`caveman:cavecrew-investigator`; multi-file -> `general-purpose`; 1-2 file edit -> `caveman:cavecrew-builder`; review -> `code-review`; vault -> `vault-search`; design -> `Plan`.

Independent units: multiple Agent calls in ONE message, full brief each. Always pass `model`: fast=`haiku`, default=`sonnet`, best=`opus`; on Fable never omit it, never dispatch `fork`.

Inline only: user decisions, commits, pushes, PRs, destructive ops, approve-per-step flows, jobs under 20 KB.

"Do it yourself", "no agents" or "inline" suspends this for the turn. Plan mode does not.
