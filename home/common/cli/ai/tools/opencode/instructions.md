## RTK Token Proxy

RTK is active via the opencode plugin (`~/.config/opencode/plugins/rtk.ts`). It auto-intercepts shell commands and compresses output before it reaches context — 60-90% token savings on git, ls, grep, test runners, etc.

**You do not need to prefix commands with `rtk`** — the plugin rewrites them transparently.

Use these meta commands directly when needed:

```bash
rtk gain              # token savings analytics for this session
rtk gain --history    # savings history across commands
rtk discover          # scan command history for missed RTK opportunities
rtk proxy <cmd>       # bypass RTK and run command raw (debugging only)
```

---

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
