{
  config,
  pkgs,
  lib,
  ...
}: let
  shared = builtins.readFile ./shared-instructions.md;
  context7 = builtins.readFile ./context7-prefix.md;
  extra = config.home.ai.extraInstructions;
  content = if extra != "" then context7 + "\n" + shared + "\n\n" + extra else context7 + "\n" + shared;
in {
  xdg.configFile."opencode/AGENTS.md" = {
    text = content;
  };
}
