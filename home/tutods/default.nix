{ pkgs, lib, ... }:

let 
  homeDirectory = "/Users/tutods";
in {
  home.username = "tutods";
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