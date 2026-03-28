{ lib, ... }:

{
  home.username      = "tutods";
  home.homeDirectory = lib.mkForce "/Users/tutods";
  home.stateVersion  = "23.11";

  imports = [
    ../programs
  ];
}
