## Model Selection for Subagents

Pick the least powerful model that fits the task.

| Tier | Model | Use when |
|------|-------|----------|
| **fast** | `haiku` | isolated functions, 1-2 files, mechanical changes |
| **default** | `sonnet` | multi-file coordination, pattern matching, integration work |
| **best** | `opus` | architecture decisions, design reviews, complex reasoning |

Aliases resolve to the latest model in each tier, so this table doesn't go stale.

On Fable sessions (main model `claude-fable-5-1`), subagents never run on Fable: always pass `model` explicitly from the tier above, never omit it (omitting inherits the parent), and never dispatch the `fork` subagent type on Fable, `fork` always inherits the parent model with no override.
