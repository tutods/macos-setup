{
  config,
  pkgs,
  lib,
  ...
}: let
  ai = import ../../../../../lib/ai.nix {inherit pkgs;};

  sharedFiles = [
    ./shared-instructions.md
    ./model-quality.md
    ./learned-rules.md
    ./ts-conventions.md
    ./react-conventions.md
    ./api-conventions.md
    ./testing-conventions.md
    ./dependency-hygiene.md
  ];

  claudeExtras = builtins.readFile ../tools/claude/instructions.md;

  sharedContent = lib.concatStringsSep "\n\n" (map builtins.readFile sharedFiles);
  extra = config.home.ai.extraInstructions or "";
in {
  # shared + claude-specific extras + role extras.
  home.file.".claude/rules/workflow.md".text =
    ai.appendIfNonEmpty (sharedContent + "\n\n" + claudeExtras) extra
    + "\n";
}
