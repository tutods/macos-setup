# AI Privacy & Local-First Strategy

## Concept
To maximize data sovereignty and minimize exposure of sensitive intellectual property or personal data, this setup implements a "Local-First" fallback strategy. While cloud-based LLMs (Claude, GPT) provide superior reasoning for general tasks, local models (via Ollama) provide a "Zero-Trust" environment where data never leaves the machine.

## When to use Local Models (Ollama)
You should explicitly switch to a local model (e.g., `ollama/qwen2.5-coder:32b`) when the task involves:
- **PII (Personally Identifiable Information)**: Processing emails, phone numbers, or addresses.
- **Secret Audits**: Analyzing configuration files that might contain keys or credentials.
- **High-Sovereignty Logic**: Working on proprietary algorithms or "secret sauce" business logic.
- **Local System Deep-Dives**: When the AI needs to analyze large portions of the local filesystem that you are uncomfortable uploading to a cloud provider.

## Implementation
1. **Model Switch**: Use `Ctrl+M` in opencode to switch the provider to `ollama`.
2. **Verification**: Ensure the model is running locally (`ollama list`).
3. **Workflow**: 
   - Use cloud models for architecture and boilerplate.
   - Use local models for the "final pass" on sensitive data.
