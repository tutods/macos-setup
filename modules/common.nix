{ pkgs, nixpkgs, ... }:
{
  # Import shared modules
  imports = [
    ./packages
  ];

  # Common system configuration
  system.stateVersion = 6;

  # Timezone
  time = {
    timeZone = "Europe/Lisbon";
  };

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };

  # Nix store optimization
  nix.optimise.automatic = true;
}
