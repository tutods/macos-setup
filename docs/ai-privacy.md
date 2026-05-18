# AI Privacy & Local-First Strategy

## Concept

To maximize data sovereignty and minimize exposure of sensitive IP or personal data, this setup implements a "Local-First" fallback strategy. Cloud LLMs (Claude, GPT) provide superior reasoning for general tasks; local models via Ollama provide a zero-trust environment where data never leaves the machine.

## When to use local models (Ollama)

Switch to a local model (e.g., `ollama/qwen2.5-coder:32b`) when the task involves:

- **PII**: Processing emails, phone numbers, or addresses
- **Secret audits**: Analyzing config files that might contain keys or credentials
- **High-sovereignty logic**: Proprietary algorithms or "secret sauce" business logic
- **Local filesystem deep-dives**: Large portions of the filesystem you're uncomfortable uploading to a cloud provider

## How to switch

1. In opencode: `Ctrl+M` to switch provider to `ollama`
2. Verify model is running: `ollama list`
3. Workflow: use cloud models for architecture and boilerplate, local models for the "final pass" on sensitive data

## Forbidden commands (AI sessions)

Never use these in an AI-assisted session — they dump environment variables and frequently expose session tokens and private keys:

```bash
env        # NEVER
printenv   # NEVER
set        # NEVER (fish shell dumps all vars)
```

## Secret access rules

- Only use `doppler` to verify key existence or inject secrets into a subprocess
- Never use `doppler` to print or log actual secret values
- Never log output from any command that contains a secret

## Data leakage prevention

- Avoid reading `~/Documents` or `~/Downloads` unless specifically requested for the current task
- Always scrub generated scripts for plaintext secrets before presenting to user
- Secrets file `~/.config/fish/secrets.fish` is explicitly blocked from Claude Code reads via `permissions.deny` in `settings.json`

## Model selection guide

| Tier | Model | Use when |
|------|-------|----------|
| **fast** | `claude-haiku-4-5` | Isolated functions, 1–2 files, mechanical changes |
| **default** | `claude-sonnet-4-6` | Multi-file coordination, pattern matching, integration work |
| **best** | `claude-opus-4-6` | Architecture decisions, design reviews, complex reasoning |
| **local** | `ollama/qwen2.5-coder:32b` | PII, secrets, proprietary logic, offline |
