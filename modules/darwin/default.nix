{ inputs, config, lib, system, pkgs, ... }:
let
  inherit (inputs) nixpkgs;
in
{
  imports = [
    ./security.nix
    ./settings.nix
    ./networking.nix
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