{...}: {
  home.file.".claude/context/stack-nix-dotfiles.md".source = ./stack-nix-dotfiles.md;
  home.file.".claude/context/stack-personal.md".source = ./stack-personal.md;
  home.file.".claude/context/stack-work.md".source = ./stack-work.md;

  xdg.configFile."opencode/context/stack-nix-dotfiles.md".source = ./stack-nix-dotfiles.md;
  xdg.configFile."opencode/context/stack-personal.md".source = ./stack-personal.md;
  xdg.configFile."opencode/context/stack-work.md".source = ./stack-work.md;
}
