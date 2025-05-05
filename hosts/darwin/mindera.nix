{ pkgs, nixpkgs, home-manager, nix-homebrew, ... }:
{

  # Host-specific configuration
  networking.hostName = "mindera-mbp";

  # User configuration
  users.users."daniel.a.sousa" = { };

  # Add Fish to /etc/shells
  environment.shells = [ pkgs.fish ];

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users."daniel.a.sousa" = import ../../home/daniel.a.sousa/default.nix;
  };

  # Homebrew configuration
  nix-homebrew = {
    enable = true;
    user = "daniel.a.sousa";
    enableRosetta = true;
    autoMigrate = true;
    mutableTaps = true;
  };
}