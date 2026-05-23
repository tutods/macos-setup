{
  config,
  lib,
  ...
}: let
  sharedFiles = [
    ./shared-instructions.md
    ./privacy-guide.md
    ./ts-conventions.md
  ];

  toolExtras = {
    claude = builtins.readFile ./claude-instructions.md;
    opencode = builtins.readFile ./opencode-instructions.md;
    codex = builtins.readFile ./codex-instructions.md;
  };

  sharedContent = lib.concatStringsSep "\n\n" (map (f: builtins.readFile f) sharedFiles);

  extra = config.home.ai.extraInstructions or "";

  appendIfNonEmpty = s: base:
    if (builtins.isList s || (builtins.isString s && s != ""))
    then
      base
      + "\n\n"
      + (
        if builtins.isList s
        then lib.concatStringsSep "\n" s
        else s
      )
    else base;

  opencodeContent = appendIfNonEmpty extra (sharedContent + "\n\n" + toolExtras.opencode) + "\n";
  claudeContent = appendIfNonEmpty extra (sharedContent + "\n\n" + toolExtras.claude) + "\n";
  # RTK proxy reference prepended so codex loads the token-proxy instructions
  codexContent = "@${config.home.homeDirectory}/.codex/RTK.md\n\n" + appendIfNonEmpty extra (sharedContent + "\n\n" + toolExtras.codex) + "\n";
in {
  # opencode — shared + opencode-specific + role extras
  xdg.configFile."opencode/AGENTS.md".text = opencodeContent;

  # Claude Code — shared + claude-specific + role extras
  home.file.".claude/rules/workflow.md".text = claudeContent;

  # Codex — RTK proxy ref + shared + codex-specific + role extras
  home.file.".codex/AGENTS.md".text = codexContent;
}
