{ pkgs, ... }:
{
  home.username = "tutods";
  home.homeDirectory = "/Users/tutods";
  home.stateVersion = "23.11"; # Prevents future breaking changes
  
  # Add your home-manager options here
  home.packages = with pkgs; [
    fish
    fzf
    zoxide
    bat
  ];

  programs.fish = {
    enable = true;
    shellInit = ''
      # fzf key bindings
      set -gx FZF_DEFAULT_COMMAND 'fd --type f'
      set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
      set -gx FZF_ALT_C_COMMAND 'fd --type d'
      set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
      # zoxide init
      zoxide init fish | source
    '';
    interactiveShellInit = ''
      # bat as default cat
      alias cat='bat'
    '';
  };

  programs.zoxide.enable = true;
  programs.fzf.enable = true;
  programs.bat.enable = true;

  # To set fish as your default shell in macOS, you need to:
  # 1. Add fish to /etc/shells
  # 2. Run chsh -s /run/current-system/sw/bin/fish
} 