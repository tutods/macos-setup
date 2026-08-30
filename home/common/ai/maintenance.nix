# Weekly eviction of Claude Code session transcripts. ~/.claude/projects grows
# without bound, the built-in cleanup never touches it. Anything older than
# pruneDays goes; nothing else is affected.
{
  config,
  pkgs,
  ...
}: let
  pruneDays = 30;
  prune = pkgs.writeShellScript "claude-prune-transcripts" ''
    set -euo pipefail
    root="${config.home.homeDirectory}/.claude/projects"
    [ -d "$root" ] || exit 0
    ${pkgs.findutils}/bin/find "$root" -type f -name '*.jsonl' -mtime +${toString pruneDays} -delete
    ${pkgs.findutils}/bin/find "$root" -mindepth 1 -type d -empty -delete 2>/dev/null || true
    echo "claude-prune-transcripts: done, cutoff ${toString pruneDays}d"
  '';
in {
  launchd.agents.claude-prune-transcripts = {
    enable = true;
    config = {
      ProgramArguments = ["${prune}"];
      StartCalendarInterval = [
        {
          Weekday = 1;
          Hour = 4;
          Minute = 0;
        }
      ];
      StandardOutPath = "${config.home.homeDirectory}/.claude/prune.log";
      StandardErrorPath = "${config.home.homeDirectory}/.claude/prune.log";
    };
  };
}
