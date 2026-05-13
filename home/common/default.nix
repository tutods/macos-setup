{
  config,
  lib,
  ...
}: {
  imports = [
    # Editors
    ./editors/vscode
    ./editors/zed
    # CLI tools
    ./cli/ai
    ./cli/bat.nix
    ./cli/gh.nix
    ./cli/git.nix
    ./cli/htop.nix
    ./cli/oh-my-posh
    # Shell
    ./shell/fish
    # Terminal
    ./terminal/ghostty
  ];

  home.activation.createDeveloperDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "${config.home.homeDirectory}/Developer" ]; then
      echo "↣ Create Developer directory"
      mkdir -p "${config.home.homeDirectory}/Developer"
    fi
  '';

  home.activation.checkSecrets = lib.hm.dag.entryAfter ["writeBoundary"] ''
    YELLOW='\033[1;33m'
    NC='\033[0m'

    if [ ! -f "${config.home.homeDirectory}/.config/git/private" ]; then
      printf "\n  ''${YELLOW}⚠  Git identity missing''${NC}\n"
      printf "  Create it with:\n"
      printf "    mkdir -p ~/.config/git\n"
      printf "    git config --file ~/.config/git/private user.name \"Your Name\"\n"
      printf "    git config --file ~/.config/git/private user.email \"you@email.com\"\n\n"
    fi

    if [ ! -f "${config.home.homeDirectory}/.config/fish/secrets.fish" ]; then
      printf "\n  ''${YELLOW}⚠  Fish secrets missing''${NC}\n"
      printf "  Create ~/.config/fish/secrets.fish if you need env vars.\n"
      printf "  It's sourced automatically by fish on startup.\n\n"
    fi
  '';
}
