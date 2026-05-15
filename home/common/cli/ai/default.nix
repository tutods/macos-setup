{pkgs, ...}: {
  imports = [
    ./claude
    ./init.nix
    ./instructions
    ./mcp
    ./options.nix
    ./skills
  ];

  home.packages = [
    pkgs.repomix
  ];
}
