{ pkgs, lib, ... }:
{
  imports = [
    ./extensions.nix
    ./keybindings.nix
    ./settings.nix
  ];
}