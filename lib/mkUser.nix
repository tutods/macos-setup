{
  username,
  role ? null,
  extraImports ? [],
  # "full", everything in home/common (editors, AI, shell).
  # "shell", home/common/core.nix only: shell, prompt, CLI tools, terminal.
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
  # home-manager's nixos/common.nix defines this as null on nix-darwin; override it.
  home.homeDirectory = lib.mkForce "/Users/${username}";
  home.stateVersion = "24.11";
  imports =
    [baseModule.${profile}]
    # Unknown roles fail evaluation; a silent skip would deploy a user with no
    # role config on a mere typo.
    ++ lib.optional (role != null) (roleModule.${role} or (throw "mkUser: unknown role '${role}'"))
    ++ extraImports;
}
