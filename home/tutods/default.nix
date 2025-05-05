{ pkgs, lib, ... }:
{
  home.username = "tutods";
  home.homeDirectory = lib.mkForce "/Users/tutods";
  home.stateVersion = "23.11"; # Prevents future breaking changes

  imports = [
    ../programs
  ];

  # Add your home-manager options here
  home.packages = with pkgs; [
    fzf
    fd
    bat
    zoxide
  ];
  # To set fish as your default shell in macOS, you need to:
  # 1. Add fish to /etc/shells
  # 2. Run chsh -s /run/current-system/sw/bin/fish
} 