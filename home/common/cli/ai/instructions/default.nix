{
  config,
  pkgs,
  lib,
  ...
}: let
  shared = builtins.readFile ./shared-instructions.md;
  context7 = builtins.readFile ./context7-prefix.md;
  extra = config.home.ai.extraInstructions;
  content =
    context7
    + "\n\n"
    + shared
    + (
      if extra != ""
      then "\n\n" + extra
      else ""
    )
    + "\n";
in {
  # opencode — full instructions (context7 + shared + role extras)
  xdg.configFile."opencode/AGENTS.md".text = content;

  # Claude Code — context7 prefix + shared + role extras
  home.file.".claude/rules/context7.md".text = context7 + "\n";
  home.file.".claude/rules/workflow.md".text =
    shared
    + (
      if extra != ""
      then "\n\n" + extra
      else ""
    )
    + "\n";
}
