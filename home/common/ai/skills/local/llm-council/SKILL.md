---
name: llm-council
description: Multi-perspective decision framework. Runs a question through five advisors with different thinking styles (Contrarian, First Principles, Expansionist, Outsider, Executor), then anonymises and peer reviews, then a Chairman gives a final recommendation. Trigger with "council", "llm council", "run the council", or when the user has a complex decision needing structured divergent-then-convergent review.
---

# LLM Council

The council runs as a workflow so the five advisors answer in genuinely
isolated contexts (they cannot converge on each other) and the anonymisation
before peer review happens in code, not on the honour system.

## Run it

The user asking for the council is the explicit opt-in to multi-agent
orchestration. Invoke the Workflow tool with the deployed script:

```
Workflow({
  scriptPath: "<home>/.claude/workflows/llm-council.js",
  args: "<the user's question, verbatim — include all context they gave>"
})
```

Resolve `<home>` to the real home directory. If the question is spread over
several messages, consolidate it into one self-contained `args` string — the
advisors see nothing but that string.

## Present the result

The workflow returns `{ question, advisors, review, recommendation }`:

1. Lead with the **Chairman's recommendation** (it is already ≤200 words).
2. Follow with the **peer review** (strongest response, biggest blind spot,
   what everyone missed).
3. Offer the five full advisor responses on request instead of pasting them —
   they are long. Name the advisors when showing them (the reviewer saw them
   anonymised; the user doesn't have to).

If the workflow fails to start (tool unavailable, script missing), say so and
offer the degraded single-context version: answer as each advisor in turn,
then review, then chairman — noting that perspectives are less independent
this way.
