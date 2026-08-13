{
  aiLib,
  lib,
  ...
}: {
  # Work-only custom skills — real dirs in ~/.claude/skills.
  # (Custom skills shared across roles live in home/common/ai/skills/default.nix.)
  imports = [
    (aiLib.mkLocalSkills {
      inherit lib;
      label = "work";
      dir = ./skills/local;
      names = ["acli" "obsidian-vault" "work-stack"];
    })
  ];

  # Stack reference is the `work-stack` skill above, not an always-on
  # instruction — it is irrelevant during Nix or content work.
  home.ai.extraInstructions = builtins.readFile ./instructions.md;

  # No work-only plugins or MCP servers. Jira is covered by the `acli` custom
  # skill above (real Atlassian CLI, with JQL/ADF/field-convention references)
  # plus the claude.ai Atlassian connector — both pm-skills@claude-code-skills
  # and the mcp-atlassian npx server were dropped as weaker extra paths to the
  # same thing.
}
