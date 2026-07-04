{
  config,
  pkgs,
  lib,
  ...
}: let
  ai = import ../../../../../lib/ai.nix {inherit pkgs;};

  sharedFiles = [
    ./shared-instructions.md
    ./privacy-guide.md
    ./ts-conventions.md
    ./react-conventions.md
    ./api-conventions.md
    ./testing-conventions.md
    ./dependency-hygiene.md
  ];

  toolExtras = {
    claude = builtins.readFile ../tools/claude/instructions.md;
    opencode = builtins.readFile ../tools/opencode/instructions.md;
  };

  sharedContent = lib.concatStringsSep "\n\n" (map builtins.readFile sharedFiles);
  extra = config.home.ai.extraInstructions or "";

  # Per-tool content: shared + tool-specific extras + role extras.
  toolContent = tool:
    ai.appendIfNonEmpty (sharedContent + "\n\n" + toolExtras.${tool}) extra
    + "\n";
in {
  xdg.configFile."opencode/AGENTS.md".text = toolContent "opencode";
  home.file.".claude/rules/workflow.md".text = toolContent "claude";
}
