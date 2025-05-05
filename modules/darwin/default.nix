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