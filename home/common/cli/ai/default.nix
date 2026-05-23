{pkgs, ...}: {
  imports = [
    ./claude
    ./codex
    ./init.nix
    ./instructions
    ./opencode
    ./options.nix
    ./skills
  ];

  home.packages = [
    pkgs.repomix
  ];
}
