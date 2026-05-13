{
  config,
  pkgs,
  lib,
  ...
}: let
  shared = builtins.readFile ./shared-instructions.md;
  context7 = builtins.readFile ./context7-prefix.md;
in {
  xdg.configFile."opencode/AGENTS.md" = {
    text = context7 + "\n" + shared;
  };
}
