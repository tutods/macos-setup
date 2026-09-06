{...}: {
  imports = [
    ./security.nix
    ./settings.nix
    ./homebrew
  ];

  system.keyboard = {
    enableKeyMapping = true;
  };

  power = {
    sleep = {
      computer = 5;
      display = 5;
      allowSleepByPowerButton = true;
    };
  };
}
