{
  aiLib,
  config,
  lib,
  ...
}: let
  # Concatenated into ~/.claude/rules/workflow.md. delegation.md is Claude-only
  # (≤1 KB); shared.md is harness-agnostic (≤4 KB), opencode reads it too.
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
