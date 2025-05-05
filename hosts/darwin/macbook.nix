{ pkgs, nixpkgs, home-manager, nix-homebrew, ... }:
{
  # Import common configuration
  imports = [
    ../../modules/common.nix
  ];

  # Host-specific configuration
  networking.hostName = "tutods-macbook";

  # User configuration
  users.users.tutods = { }; # Most config in home-manager

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.tutods = import ../../home/tutods/default.nix;
  };

  # Homebrew configuration
  nix-homebrew = {
    enable = true;
    user = "tutods";
    enableRosetta = true;
    autoMigrate = true;
    mutableTaps = true;
  };
}