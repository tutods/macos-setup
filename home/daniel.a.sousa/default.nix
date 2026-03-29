{ lib, ... }:

{
  home.username      = "daniel.a.sousa";
  home.homeDirectory = lib.mkForce "/Users/daniel.a.sousa";
  home.stateVersion  = "23.11";

  imports = [
    ../programs
  ];
}
