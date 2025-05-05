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
    # Dependencies for fzf.fish plugin
    fzf
    fd
    bat
    zoxide
  ];

  # programs.fish = {
  #   enable = true;
  #   shellInit = ''
  #     # fzf key bindings
  #     set -gx FZF_DEFAULT_COMMAND 'fd --type f'
  #     set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
  #     set -gx FZF_ALT_C_COMMAND 'fd --type d'
  #     set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
  #     # zoxide init
  #   '';
  # };

  # programs.zoxide.enable = true;
  # programs.fzf.enable = true;
  # programs.bat.enable = true;

  # To set fish as your default shell in macOS, you need to:
  # 1. Add fish to /etc/shells
  # 2. Run chsh -s /run/current-system/sw/bin/fish
} 