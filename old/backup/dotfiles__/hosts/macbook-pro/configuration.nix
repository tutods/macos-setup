{ pkgs, home-manager, ... }:

{
  imports = [
    ../../darwin
  ];

  users.users.tutods = {
    name = "tutods";
    home = "/Users/tutods";
  };

  security.pam.enableSudoTouchIdAuth = true;
}