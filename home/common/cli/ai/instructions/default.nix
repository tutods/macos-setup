{
  config,
  lib,
  ...
}: let
  shared = builtins.readFile ./shared-instructions.md;
  extra = config.home.ai.extraInstructions;
  content =
    shared
    + (
      if extra != ""
      then "\n\n" + extra
      else ""
    )
    + "\n";
in {
  # opencode — shared instructions + role extras
  xdg.configFile."opencode/AGENTS.md".text = content;

  # Claude Code — shared instructions + role extras
  home.file.".claude/rules/workflow.md".text = content;
}
