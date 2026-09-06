# Weekly eviction of opencode's on-disk history, the opencode counterpart of
# home/common/ai/maintenance.nix (shared, Claude transcripts): opencode is
# personal-only, so its prune lives in this role, not in common. Both
# ~/.local/share/opencode/log (one file per run) and .../storage (session and
# message JSON) grow without bound; anything older than pruneDays goes.
# auth.json sits at the data dir's top level, outside both pruned subtrees,
# and is never touched.
{
  config,
  pkgs,
  ...
}: let
  pruneDays = 30;
  prune = pkgs.writeShellScript "opencode-prune-data" ''
    set -euo pipefail
    root="${config.home.homeDirectory}/.local/share/opencode"
    for dir in "$root/log" "$root/storage"; do
      [ -d "$dir" ] || continue
      ${pkgs.findutils}/bin/find "$dir" -type f -mtime +${toString pruneDays} -delete
      ${pkgs.findutils}/bin/find "$dir" -mindepth 1 -type d -empty -delete 2>/dev/null || true
    done
    echo "opencode-prune-data: done, cutoff ${toString pruneDays}d"
  '';
in {
  launchd.agents.opencode-prune-data = {
    enable = true;
    config = {
      ProgramArguments = ["${prune}"];
      StartCalendarInterval = [
        {
          Weekday = 1;
          Hour = 4;
          Minute = 15;
        }
      ];
      StandardOutPath = "${config.home.homeDirectory}/.local/share/opencode/prune.log";
      StandardErrorPath = "${config.home.homeDirectory}/.local/share/opencode/prune.log";
    };
  };
}
