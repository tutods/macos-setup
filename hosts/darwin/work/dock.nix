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
      "/System/Applications/Mail.app"
      "/System/Applications/Calendar.app"
      {
        spacer = {
          small = false;
        };
      }
      "/Applications/Zed.app"
      "/Applications/Nix Apps/Visual Studio Code.app"
      "/Applications/Warp.app"
      {
        spacer = {
          small = false;
        };
      }
    ];
    persistent-others = [
      "/Users/daniel.a.sousa/Downloads"
      "/Users/daniel.a.sousa/Developer"
    ];
  };
}
