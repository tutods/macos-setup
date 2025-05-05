{ config, ... }:

{
  system.defaults.dock = {
    persistent-apps = [
      "/System/Applications/Launchpad.app"
      {
        spacer = {
          small = false;
        };
      }
      "/Applications/Safari.app"
      "/Applications/Zen.app"
      "/System/Applications/Mail.app"
      "/System/Applications/Calendar.app"
      {
        spacer = {
          small = false;
        };
      }
      "/Applications/Cursor.app"
      "/Applications/Windsurf.app"
      "/Applications/Visual Studio Code.app"
      "/Applications/Hyper.app"
      {
        spacer = {
          small = false;
        };
      }
    ];
    persistent-others = [
      "${config.users.users.tutods.home}/Downloads"
      "${config.users.users.tutods.home}/Developer"
    ];
  };
}
