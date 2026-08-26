## Model Selection for Subagents

Pick the least powerful model that fits the task.

| Tier | Model | Use when |
|------|-------|----------|
| **fast** | `haiku` | isolated functions, 1-2 files, mechanical changes |
| **default** | `sonnet` | multi-file coordination, pattern matching, integration work |
| **best** | `opus` | architecture decisions, design reviews, complex reasoning |

Aliases resolve to the latest model in each tier, so this table doesn't go stale.
