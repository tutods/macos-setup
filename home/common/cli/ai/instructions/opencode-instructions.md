## Model Selection

Pick the least powerful model that fits the task.

### Anthropic (default provider)

| Tier | Model | Use when |
|------|-------|----------|
| **fast** | `anthropic/claude-haiku-4-5-20251001` | mechanical changes, isolated functions, 1-2 files |
| **default** | `anthropic/claude-sonnet-4-6` | standard multi-file work, integration tasks |
| **best** | `anthropic/claude-opus-4-6` | architecture, design reviews, complex reasoning |

### z.AI (GLM — coding plan)

| Tier | Model | Use when |
|------|-------|----------|
| **fast** | `zhipu/glm-z1-flash` | quick edits, simple lookups, cheap iterations |
| **default** | `zhipu/glm-4.7` | multi-file TypeScript/frontend work |
| **best** | `zhipu/glm-5.1` | deep reasoning, architecture, replaces Opus |

### Ollama (local/private)

| Tier | Model | Use when |
|------|-------|----------|
| **fast** | `ollama/qwen2.5-coder:7b` | offline quick edits, no network |
| **default** | `ollama/qwen2.5-coder:32b` | offline multi-file coding tasks |

Switch model mid-session: `Ctrl+M` in opencode to change without losing context.
