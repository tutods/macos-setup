{
  aiLib,
  config,
  lib,
  ...
}: let
  # Concatenated into ~/.claude/rules/workflow.md, loaded in every session.
  # delegation.md is Claude-only and capped at 1 KB; shared.md is harness-agnostic
  # (opencode reads it too) and capped at 4 KB. Stack-specific rules go in a skill.
  sharedFiles = [
    ./delegation.md
    ./shared.md
  ];

  sharedContent = lib.concatStringsSep "\n\n" (map builtins.readFile sharedFiles);
  extra = config.home.ai.extraInstructions;
in {
  home.file.".claude/rules/workflow.md".text =
    aiLib.appendIfNonEmpty sharedContent extra
    + "\n";
}
