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
#           [ "/Applications/Zed.app" ]
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
  wrapGroup = g: [spacer] ++ g;
in {
  system.defaults.dock = {
    persistent-apps = lib.concatMap wrapGroup groups ++ [spacer];
    persistent-others = map (d: "/Users/${config.system.primaryUser}/${d}") others;
  };
}
