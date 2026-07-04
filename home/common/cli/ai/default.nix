{pkgs, ...}: {
  imports = [
    ./context
    ./init.nix
    ./instructions
    ./options.nix
    ./rtk
    ./tools/claude
    ./tools/opencode
    ../../../../skills
  ];

  home.packages = [
    pkgs.repomix
  ];
}
