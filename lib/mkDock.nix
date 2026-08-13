# Shared dock layout factory.
#
# Each host passes its app groups; spacer wrapping, the closing spacer, and
# the persistent-others resolution are identical across all hosts.
#
# Usage in a host dock.nix:
#   { mkDock, ... }: {
#     imports = [
#       (mkDock {
#         groups = [
#           [ "/Applications/Firefox.app" "/System/Applications/Mail.app" ]
#           # {home = "..."} resolves against the primary user's home —
#           # never hardcode /Users/<name> in a host file.
#           [ "/Applications/Zed.app" {home = "Applications/Home Manager Apps/Foo.app";} ]
#         ];
#       })
#     ];
#   }
{
  groups,
  others ? ["Downloads" "Developer"],
}: {
  config,
  lib,
  ...
}: let
  spacer = {spacer = {small = false;};};
  resolveApp = a:
    if builtins.isAttrs a && a ? home
    then "/Users/${config.system.primaryUser}/${a.home}"
    else a;
  wrapGroup = g: [spacer] ++ map resolveApp g;
in {
  system.defaults.dock = {
    persistent-apps = lib.concatMap wrapGroup groups ++ [spacer];
    persistent-others = map (d: "/Users/${config.system.primaryUser}/${d}") others;
  };
}
