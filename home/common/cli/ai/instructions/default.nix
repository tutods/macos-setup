{
  config,
  lib,
  ...
}: let
  # Files to include in the shared instructions
  sharedFiles = [
    ./shared-instructions.md
    ./privacy-guide.md
  ];

  # Component-specific instructions
  toolExtras = {
    claude = builtins.readFile ./claude-instructions.md;
    opencode = builtins.readFile ./opencode-instructions.md;
  };

  # Combine all shared files into one string
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
in {
  # opencode — shared + opencode-specific + role extras
  xdg.configFile."opencode/AGENTS.md".text = opencodeContent;

  # Claude Code — shared + claude-specific + role extras
  home.file.".claude/rules/workflow.md".text = claudeContent;
}
