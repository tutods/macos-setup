# ── Custom workflows — shared across every role ───────────────────────────────
#
# Workflow scripts for Claude Code's Workflow tool, symlinked into
# ~/.claude/workflows/<name>.js by lib/ai.nix:mkLocalWorkflows.
#
# Boundary vs skills and agents: skills are knowledge, agents are one isolated
# context with judgement, workflows are deterministic multi-agent fan-out
# (parallel perspectives, verification gates). A skill can stay as the trigger
# that tells Claude to invoke the workflow — see skills/local/llm-council.
#
{
  aiLib,
  lib,
  ...
}: {
  imports = [
    (aiLib.mkLocalWorkflows {
      inherit lib;
      label = "common";
      dir = ./local;
      names = ["llm-council"];
    })
  ];
}
