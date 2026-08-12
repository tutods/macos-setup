{
  aiLib,
  config,
  lib,
  ...
}: let
  # Always-on instructions only — these are concatenated into
  # ~/.claude/rules/workflow.md and load in *every* session.
  #
  # Stack-specific conventions (TypeScript, React, API, testing, dependency
  # hygiene) deliberately live in skills/local/ instead: they are irrelevant
  # when the session is about Nix or content, and as skills they load on demand
  # rather than costing ~2.5k tokens up front. Add here only if it must apply
  # to every session regardless of what is being worked on.
  sharedFiles = [
    ./shared-instructions.md
    ./model-quality.md
    ./learned-rules.md
    ./model-selection.md
  ];

  sharedContent = lib.concatStringsSep "\n\n" (map builtins.readFile sharedFiles);
  extra = config.home.ai.extraInstructions or "";
in {
  # shared instructions + role extras.
  home.file.".claude/rules/workflow.md".text =
    aiLib.appendIfNonEmpty sharedContent extra
    + "\n";
}
