# Shared user configuration factory.
# Accepts username and optional extra imports for per-context overrides.
#
# Usage in a host default.nix:
#   homeConfig = mkUser {
#     username     = "tutods";
#     extraImports = [ ../../../home/programs/personal ];
#   };
{
  username,
  extraImports ? [],
}: {lib, ...}: {
  home.username = username;
  home.homeDirectory = lib.mkForce "/Users/${username}";
  home.stateVersion = "23.11";
  imports = [../home/programs] ++ extraImports;
}
