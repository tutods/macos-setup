{ pkgs, nixpkgs, ... }:
{
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
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
}