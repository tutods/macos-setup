## Model Selection for Subagents

Pick the least powerful model that fits the task:

| Tier | Model ID | Use when |
|------|----------|----------|
| **fast** | `claude-haiku-4-5-20251001` | isolated functions, 1-2 files, mechanical changes |
| **default** | `claude-sonnet-4-6` | multi-file coordination, pattern matching, integration work |
| **best** | `claude-opus-4-6` | architecture decisions, design reviews, complex reasoning |
