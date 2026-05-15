{pkgs, ...}: {
  imports = [
    ./claude
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
