{ pkgs, nixpkgs, ... }:
{
  # Allow unfree packages (like VSCode)
  nixpkgs.config.allowUnfree = true;

  # Import shared modules
  imports = [
    ./packages/common-packages.nix
    ./darwin
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
