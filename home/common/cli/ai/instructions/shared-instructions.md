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

## Repository Conventions

- Always check `flake.nix` and `CLAUDE.md` before suggesting package changes
- Validate changes with `./nix.sh <host> --build-only`
- Only commit when explicitly asked
- Do not add comments unless requested
- Packages go in `modules/packages/` (system) or `home/common/` (Home Manager)
- Homebrew casks go in `modules/darwin/homebrew/casks/` (shared) or `hosts/darwin/<name>/homebrew/casks/` (per-machine)
- Private data (secrets, git identity) is never committed — see `docs/secrets.md`

## General Workflow

- Use `rg` for searching file contents, `fd` for finding files by name
- Use `fzf` for interactive selection, search, and filtering
- Use `bat` for reading files when syntax highlighting helps
- Use `rtk` for git operations and command execution when available
- Prefer Nix-managed tools over ad-hoc installs
- When editing files, prefer the Edit tool over Bash with sed/awk