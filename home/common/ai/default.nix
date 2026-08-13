# ── AI tooling ────────────────────────────────────────────────────────────────
#
# Claude Code is the only agent, and every module in this directory writes into
# ~/.claude/ — instructions, skills, settings, plugins, MCP servers, statusline.
# There is deliberately no `claude/` subdirectory: it would not separate Claude
# things from non-Claude things, because there are no non-Claude things.
#
# Role-specific additions live in home/roles/<role>/ai/, which mirrors this
# shape (default.nix, instructions.md, skills/local/).
#
{
  imports = [
    ./options.nix
    ./init.nix
    ./instructions
    ./skills
    ./agents
    ./workflows
    ./settings.nix
    ./plugins.nix
    ./mcp.nix
    ./statusline.nix
    ./rtk
  ];
}
