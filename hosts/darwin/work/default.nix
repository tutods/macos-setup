{ pkgs, nixpkgs, home-manager, nix-homebrew, ... }:
{
  imports = [
    ./dock.nix
    ./homebrew
  ];

  # Host-specific configuration
  networking.hostName = "daniel.a.sousa";

  # Primary user
  system.primaryUser = "daniel.a.sousa";

  # Add Fish to /etc/shells
  environment.shells = [ pkgs.fish ];

  # User configuration
  users.users.daniel.a.sousa = {
    shell = pkgs.fish; # Set Fish as default shell
    ignoreShellProgramCheck = true;
  }; # Most config in home-manager

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit pkgs; };
    backupFileExtension = "backup";
    users.daniel.a.sousa = import ../../../home/daniel.a.sousa/default.nix;
  };

  programs.fish = {
    enable = true;
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
