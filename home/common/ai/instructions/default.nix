{
  aiLib,
  config,
  lib,
  ...
}: let
  # Concatenated into ~/.claude/rules/workflow.md, loaded in every session. Add
  # here only if it applies regardless of what is being worked on, anything
  # stack-specific belongs in a skill, which loads on demand.
  sharedFiles = [
    ./delegation.md
    ./shared-instructions.md
    ./model-quality.md
    ./learned-rules.md
    ./model-selection.md
  ];

  sharedContent = lib.concatStringsSep "\n\n" (map builtins.readFile sharedFiles);
  extra = config.home.ai.extraInstructions;
in {
  home.file.".claude/rules/workflow.md".text =
    aiLib.appendIfNonEmpty sharedContent extra
    + "\n";
}
