{
  username,
  role ? null,
  extraImports ? [],
  # "full" — everything in home/common (editors, AI, shell).
  # "shell" — home/common/core.nix only: shell, prompt, CLI tools, terminal.
  #           For secondary accounts (e.g. the work admin user) that should
  #           share the shell experience without editor/AI wiring.
  profile ? "full",
}: {lib, ...}: let
  roleModule = {
    personal = ../home/roles/personal;
    work = ../home/roles/work;
  };
  baseModule = {
    full = ../home/common;
    shell = ../home/common/core.nix;
  };
in {
  home.username = username;
  home.homeDirectory = lib.mkForce "/Users/${username}";
  home.stateVersion = "24.11";
  imports =
    [baseModule.${profile}]
    ++ lib.optional (role != null && roleModule ? ${role}) roleModule.${role}
    ++ extraImports;
}
