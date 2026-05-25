{pkgs, ...}: {
  imports = [
    ./claude
    ./codex
    ./context
    ./init.nix
    ./instructions
    ./opencode
    ./options.nix
    ./rtk
    ./skills
  ];

  home.packages = [
    pkgs.repomix
  ];
}
