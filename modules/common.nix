{
  pkgs,
  nixpkgs,
  ...
}: {
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
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      interval = { Weekday = 7; Hour = 3; Minute = 0; };
      options = "--delete-older-than 7d";
    };

    optimise.automatic = true;
  };
}
