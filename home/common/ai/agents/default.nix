# ── Custom subagents — shared across every role ────────────────────────────────
#
# In-repo agent sources only. External agents come bundled inside a Claude Code
# plugin (home/common/ai/plugins.nix) — there is no separate agent-plugin channel.
#
# Installed as home.file symlinks into ~/.claude/agents, not copied like skills —
# see lib/ai.nix:mkLocalAgents for why. Role-specific agents would live in
# home/roles/<role>/ai/agents/local/ and install the same way.
#
{
  aiLib,
  lib,
  ...
}: {
  imports = [
    (aiLib.mkLocalAgents {
      inherit lib;
      label = "common";
      dir = ./local;
      names = [
        "code-reviewer"
        "dev-lifecycle"
        "reorganize-obsidian-vault"
        "vault-lint"
        "vault-search"
      ];
    })
  ];
}
