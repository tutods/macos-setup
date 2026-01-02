{ config, ... }:

{
  system.defaults.dock = {
    persistent-apps = [
      # "/System/Applications/Launchpad.app"
      {
        spacer = {
          small = false;
        };
      }
      "/Applications/Firefox.app"
      "/Applications/Safari.app"
      "/Applications/Arc.app"
      "/Applications/Google Chrome.app"
      "/System/Applications/Mail.app"
      "/System/Applications/Calendar.app"
      {
        spacer = {
          small = false;
        };
      }
      "/Applications/Cursor.app"
      "/Applications/Windsurf.app"
      "/Applications/Zed.app"
      "/Applications/Nix Apps/Visual Studio Code.app"
      "/Applications/Hyper.app"
      {
        spacer = {
          small = false;
        };
      }
    ];
    persistent-others = [
      "/Users/tutods/Downloads"
      "/Users/tutods/Developer"
    ];
  };
}
