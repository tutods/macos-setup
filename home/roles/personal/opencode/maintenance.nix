# Weekly eviction of opencode's on-disk history, the opencode counterpart of
# home/common/ai/maintenance.nix (shared, Claude transcripts): opencode is
# personal-only, so its prune lives in this role, not in common.
#
# Two storage shapes, two mechanisms:
#  - ~/.local/share/opencode/log/opencode.log is one append-only file that
#    grows to tens of MB. An -mtime test never deletes it (every write
#    refreshes its mtime), so it is truncated in place once it passes a size
#    cap instead of aged out.
#  - ~/.local/share/opencode/opencode.db is SQLite and holds the real bulk
#    (hundreds of MB of message/part rows). The old `storage/` directory this
#    module used to prune no longer exists: opencode moved sessions into the
#    db, so the prune had been a no-op on the one thing that grows. Sessions
#    older than pruneDays are deleted through the session table, and the
#    declared ON DELETE CASCADE takes their messages, parts and
#    session_messages with them; VACUUM then returns the freed pages to the
#    filesystem, which plain DELETE does not.
#
# auth.json sits at the data dir's top level, outside both, and is never
# touched.
{
  config,
  pkgs,
  ...
}: let
  pruneDays = 30;
  # Truncate the log once it passes this; generous enough to keep a useful
  # debugging window, small enough that it cannot quietly reach 100s of MB.
  logMaxBytes = 50 * 1024 * 1024;
  prune = pkgs.writeShellScript "opencode-prune-data" ''
    set -euo pipefail
    root="${config.home.homeDirectory}/.local/share/opencode"
    db="$root/opencode.db"
    log="$root/log/opencode.log"

    if [ -f "$log" ]; then
      size=$(/bin/stat -f %z "$log" 2>/dev/null || echo 0)
      if [ "$size" -gt ${toString logMaxBytes} ]; then
        : > "$log"
        echo "opencode-prune-data: truncated log ($size bytes > ${toString logMaxBytes})"
      fi
    fi

    if [ -f "$db" ] && ${pkgs.sqlite}/bin/sqlite3 "$db" "SELECT 1;" >/dev/null 2>&1; then
      # strftime runs inside sqlite so no BSD/GNU date -v/-d split to get wrong.
      # ON DELETE CASCADE takes message, part and session_message children.
      before=$(${pkgs.sqlite}/bin/sqlite3 "$db" "SELECT COUNT(*) FROM session;")
      ${pkgs.sqlite}/bin/sqlite3 "$db" \
        "PRAGMA foreign_keys=ON;
         DELETE FROM session
          WHERE time_created < (strftime('%s','now') - ${toString pruneDays} * 86400) * 1000;" >/dev/null
      after=$(${pkgs.sqlite}/bin/sqlite3 "$db" "SELECT COUNT(*) FROM session;")
      ${pkgs.sqlite}/bin/sqlite3 "$db" "VACUUM;" >/dev/null 2>&1 || true
      echo "opencode-prune-data: db sessions removed=$((before - after)) (kept $after), vacuumed"
    fi

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
  # sqlite3 for the db prune; both are referenced by store path in the script
  # above, so this keeps them out of the global package set.
  home.packages = [pkgs.sqlite];
}
