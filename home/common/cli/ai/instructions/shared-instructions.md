## Fast CLI Tool Preferences

Always prefer these tools over slower alternatives:

| Use | Instead of | Why |
|-----|-----------|-----|
| `rg` | `grep` | 10x faster content search |
| `fd` | `find` | 10x faster file finding |
| `fzf` | Manual selection | Fuzzy finder for interactive search, multi-select, and filtering |
| `bat --style=plain` | `cat` | Syntax highlighting, Git integration |
| `jq` | Manual JSON parsing | Native fast JSON processing |
| `rtk` | Raw commands | Token proxy, reduces LLM token usage by 60-90% |
| `eza` | `ls` | Icons, Git status, tree view |
| `delta` | `diff` | Better diff rendering |
| `htop` | `top` | Interactive process viewer |
| `pnpm` | `npm`/`yarn` | Faster, disk-efficient, strict dependency resolution |
| `biome` | `eslint`+`prettier` | Unified lint+format, 10x faster than eslint |

## General Workflow

- Use `rg` for searching file contents, `fd` for finding files by name
- Use `fzf` for interactive selection, search, and filtering
- Use `bat` for reading files when syntax highlighting helps
- Use `rtk` for git operations and command execution when available
- Prefer Nix-managed tools over ad-hoc installs
- When editing files, prefer the Edit tool over Bash with sed/awk
- Always run type checks (`pnpm typecheck` or `tsc --noEmit`) before declaring a task complete
- Prefer targeted edits over rewriting entire files
- Use type-safe patterns — avoid `any`, prefer branded types and Zod schemas for runtime validation