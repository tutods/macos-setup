{ pkgs, nixpkgs, home-manager, nix-homebrew, ... }:
{
  imports = [
    ./dock.nix
  ];

  # Host-specific configuration
  networking.hostName = "tutods-macbook";

  # User configuration
  users.users.tutods = {
    shell = pkgs.fish; # Set Fish as default shell
    ignoreShellProgramCheck = true;
  }; # Most config in home-manager
  
  # Add Fish to /etc/shells
  environment.shells = [ pkgs.fish ];
  
  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit pkgs; };
    users.tutods = import ../../../home/tutods/default.nix;
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