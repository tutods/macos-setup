{ inputs, config, lib, system, pkgs, ... }:
let
  inherit (inputs) nixpkgs;
in
{
  imports = [
    ./homebrew
    ./settings.nix
    ./security.nix
    ./networking.nix
  ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };
  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = lib.mkDefault "${system}";
  };
  system.stateVersion = 6;

  time = {
    timeZone = "Europe/Lisbon";
  };

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

  # programs.zsh = {
  #   enable = true;
  #   enableCompletion = true;
  #   promptInit = builtins.readFile ./../../../data/mac-dot-zshrc;
  # };
}