{
  username,
  role ? null,
  extraImports ? [],
}: {lib, ...}: let
  roleModule = {
    personal = ../home/roles/personal.nix;
    work = ../home/roles/work.nix;
  };
in {
  home.username = username;
  home.homeDirectory = lib.mkForce "/Users/${username}";
  home.stateVersion = "24.11";
  imports =
    [../home/common]
    ++ lib.optional (role != null && roleModule ? ${role}) roleModule.${role}
    ++ extraImports;
}
