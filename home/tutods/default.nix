{ config, inputs, pkgs, lib, ... }:
{
  home.stateVersion = "23.11";
  home.homeDirectory = lib.mkForce "/Users/tutods";
  
  imports = [
    ../programs
  ];

  # list of programs
  # https://mipmip.github.io/home-manager-option-search
  
  programs.lf.enable = true;

  # programs.home-manager.enable = true;
  # programs.nix-index.enable = true;
}
