# Terminal-level essentials: shell, prompt, CLI tools, terminal emulator config.
# Split out of default.nix so a secondary account (e.g. the work machine's
# admin user) can get the full shell experience without editors or AI wiring,
# see lib/mkUser.nix `profile = "shell"`.
{
  imports = [
    # General home options
    ./options.nix
    # CLI tools
    ./cli/bat.nix
    ./cli/gh.nix
    ./cli/git.nix
    ./cli/htop.nix
    # Shell
    ./shell/fish
    ./shell/oh-my-posh
    # Terminal
    ./terminal/ghostty
  ];
}
