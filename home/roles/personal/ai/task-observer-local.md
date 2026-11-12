
## Local setup (dotfiles flake)

- Skills under `~/.claude/skills` and `~/.agents/skills` are deploy-time copies of Nix sources (category b): never edit them in place, the next deploy overwrites the edit.
- Apply an approved skill edit to its source in `~/.dotfiles`: `home/common/ai/skills/local/<name>` or the role's `ai/skills/<name>`. A fetched skill has no local source: change the patch in the role's `ai/default.nix` or drop the skill.
- Outcomes that are not skill edits (corrections, principles, standing rules) go to the Obsidian vault through the `obsidian-vault` skill. Never create a second principles file.
