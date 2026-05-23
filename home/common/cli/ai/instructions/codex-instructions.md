## Model Selection

Pick the least powerful model that fits the task:

| Tier | Model | Use when |
|------|-------|----------|
| **fast** | `o4-mini` | mechanical changes, isolated functions, 1-2 files |
| **default** | `gpt-5.5` | standard multi-file work, integration tasks |
| **best** | `o3` | architecture, design reviews, complex reasoning |

## Available Tools

- `rtk` — token proxy, pre-configured via `rtk init --codex`; prefix all shell commands with `rtk`
- `graphify` — code-review graph (`graphify --platform codex` already registered)
- `code-review-graph` — PR review graph generation (`code-review-graph <pr-url>`)
- `ttok` — token counter (`ttok -m gpt-5.5 < file.ts`)
- `repomix` — pack repo context for handoff (`repomix --output context.xml`)

## Primary Use Case

Codex is best for isolated throwaway scripts and one-shot shell tasks.
For multi-file coding work, prefer `claude-code`.
For multi-provider or mid-session model switching, prefer `opencode`.
