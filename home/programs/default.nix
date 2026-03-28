{ config, ... }:

{
  imports = [
    # Apps
    ./apps/vscode
    # CLI tools
    ./cli/bat.nix
    ./cli/git.nix
    ./cli/htop.nix
    ./cli/oh-my-posh
    # Shell
    ./shell/fish
    # Terminal
    ./apps/terminal/ghostty
  ];

  # Ensure ~/Developer exists on every machine
  home.activation.createDeveloperDir = ''
    if [ ! -d "${config.home.homeDirectory}/Developer" ]; then
      echo "↣ Create Developer directory"
      mkdir -p "${config.home.homeDirectory}/Developer"
    fi
  '';
}
