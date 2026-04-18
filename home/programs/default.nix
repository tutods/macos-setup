{config, ...}: {
  imports = [
    # Editors
    ./editors/vscode
    ./editors/zed
    # CLI tools
    ./cli/bat.nix
    ./cli/gh.nix
    ./cli/git.nix
    ./cli/htop.nix
    ./cli/mas.nix
    ./cli/oh-my-posh
    # Shell
    ./shell/fish
    # Terminal
    ./terminal/ghostty
  ];

  home.activation.createDeveloperDir = ''
    if [ ! -d "${config.home.homeDirectory}/Developer" ]; then
      echo "↣ Create Developer directory"
      mkdir -p "${config.home.homeDirectory}/Developer"
    fi
  '';
}
