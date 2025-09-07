{ pkgs, nixpkgs, home-manager, nix-homebrew, ... }:
{
  imports = [
    ./dock.nix
  ];

  # Primary user
  system.primaryUser = "tutods";

  # Host-specific configuration
  networking.hostName = "tutods-macbook";

  # Add Fish to /etc/shells
  environment.shells = [ pkgs.fish ];

  # User configuration
  users.users.tutods = {
    shell = pkgs.fish; # Set Fish as default shell
    ignoreShellProgramCheck = true;
  }; # Most config in home-manager
  
  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit pkgs; };
    backupFileExtension = "backup";
    users.tutods = import ../../../home/tutods/default.nix;
  };

  programs.fish = {
    enable = true;
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