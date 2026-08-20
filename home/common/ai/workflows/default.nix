# Workflow scripts for Claude Code's Workflow tool. See docs/ai-setup.md for
# the skills/agents/workflows boundary.
{
  aiLib,
  lib,
  ...
}: {
  imports = [
    (aiLib.mkLocalWorkflows {
      inherit lib;
      dir = ./local;
      names = ["llm-council"];
    })
  ];
}
