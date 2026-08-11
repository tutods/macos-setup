{pkgs, ...}: {
  imports = [
    ./context
    ./init.nix
    ./instructions
    ./options.nix
    ./rtk
    ./tools/claude
    ../../../../skills
  ];

  home.packages = [
    pkgs.repomix
  ];
}
