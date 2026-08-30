## Model Selection (opencode, Ollama Cloud)

Pick the least powerful model that fits the task. All models are Ollama Cloud; the provider prefix is `ollama-cloud/`.

| Tier | Model | Use when |
|------|-------|----------|
| **fast** | `ollama-cloud/glm-5.3-flash` | isolated functions, 1-2 files, mechanical changes, vault lookups |
| **default** | `ollama-cloud/glm-5.3` | multi-file coordination, pattern matching, integration work |
| **best** | `ollama-cloud/deepseek-v4-pro` | architecture decisions, design reviews, complex reasoning |
| **background** | `ollama-cloud/gpt-oss:20b` | titles, summaries (set as `small_model`, not dispatched) |

`config.nix` is the machine-readable source of this table; change both together.

### Council seats

The `/council` command fans a question out to five advisor seats, one model family each so no two advisors share training biases, then a sixth family peer-reviews blind:

| Seat | Model | Family |
|------|-------|--------|
| `council-first-principles` | `ollama-cloud/deepseek-v4-pro` | DeepSeek |
| `council-expansionist` | `ollama-cloud/kimi-k3` | Moonshot |
| `council-outsider` | `ollama-cloud/minimax-m3` | MiniMax |
| `council-executor` | `ollama-cloud/qwen3.5:397b` | Alibaba |
| `council-contrarian` | `ollama-cloud/nemotron-3-ultra` | NVIDIA |
| `council-peer-review` | `ollama-cloud/gpt-oss:120b` | OpenAI |

The Ollama plan allows 3 concurrent requests, so the five seats run in two waves. Avoid models slated for retirement (check `docs.ollama.com/cloud` before swapping a seat).