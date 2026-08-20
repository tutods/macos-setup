{
  config,
  lib,
  ...
}: {
  imports = [
    # Shell, prompt, CLI tools, terminal, also usable standalone via
    # mkUser's `profile = "shell"` (see core.nix)
    ./core.nix
    # Editors
    ./editors/vscode
    ./editors/zed
    # AI (Claude Code): instructions, skills, plugins, MCP
    ./ai
  ];

  home.activation.createDeveloperDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "${config.home.homeDirectory}/Developer" ]; then
      echo "↣ Create Developer directory"
      mkdir -p "${config.home.homeDirectory}/Developer"
    fi
  '';

  # Obsidian vault, doubling as Claude Code's durable notes store, read via
  # the obsidian-vault skill (home/common/ai/skills/local). Created once, never
  # touched again by activation, so notes survive every deploy.
  home.activation.createObsidianVault = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "${config.home.homeDirectory}/Obsidian" ]; then
      echo "↣ Create Obsidian vault"
      mkdir -p "${config.home.homeDirectory}/Obsidian"
      install -m 0644 ${./obsidian-index.md} "${config.home.homeDirectory}/Obsidian/Index.md"
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
