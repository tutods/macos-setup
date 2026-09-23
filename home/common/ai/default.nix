# Everything here writes into ~/.claude/. Role-specific additions live in
# home/roles/<role>/ai/, which mirrors this shape.
{
  imports = [
    ./options.nix
    ./instructions
    ./skills
    ./agents
    ./workflows
    ./settings.nix
    ./plugins.nix
    ./statusline.nix
    ./maintenance.nix
  ];
}
