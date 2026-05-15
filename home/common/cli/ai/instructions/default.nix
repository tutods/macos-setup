{
  config,
  lib,
  ...
}: let
  shared = builtins.readFile ./shared-instructions.md;
  claudeExtra = builtins.readFile ./claude-instructions.md;
  opencodeExtra = builtins.readFile ./opencode-instructions.md;
  extra = config.home.ai.extraInstructions;

  appendIfNonEmpty = s: base:
    if s != ""
    then base + "\n\n" + s
    else base;

  opencodeContent = appendIfNonEmpty extra (shared + "\n\n" + opencodeExtra) + "\n";
  claudeContent = appendIfNonEmpty extra (shared + "\n\n" + claudeExtra) + "\n";
in {
  # opencode — shared + opencode-specific + role extras
  xdg.configFile."opencode/AGENTS.md".text = opencodeContent;

  # Claude Code — shared + claude-specific + role extras
  home.file.".claude/rules/workflow.md".text = claudeContent;
}
