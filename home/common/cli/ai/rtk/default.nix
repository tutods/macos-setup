{...}: {
  home.file.".claude/RTK.md" = {
    source = ./claude-RTK.md;
    force = true;
  };
  home.file.".codex/RTK.md" = {
    source = ./codex-RTK.md;
    force = true;
  };
  xdg.configFile."opencode/plugins/rtk.ts".source = ./opencode-rtk.ts;
}
