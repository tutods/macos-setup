{ pkgs, lib, ... }:

let 
  homeDirectory = "/Users/daniel.a.sousa";
in {
  home.username = "daniel.a.sousa";
  home.homeDirectory = lib.mkForce homeDirectory;
  home.stateVersion = "23.11"; # Prevents future breaking changes

  home.activation.post = ''
    # Create Developer directory if it doesn't exist
    if [ ! -d "${homeDirectory}/Developer" ]; then
      echo "↣ Create Developer directory"
      mkdir -p "${homeDirectory}/Developer"
    else
      echo "↣ Developer directory already exists"
    fi
  '';

  # Add your home-manager options here
  home.packages = with pkgs; [
    fish
  ];

  # TODO: check
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

  home.shell = pkgs.fish;
} 