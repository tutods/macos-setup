{ config, ... }:

{
  system.defaults.dock = {
    persistent-apps = [
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
      "/Users/daniel.a.sousa/Applications/Home Manager Apps/Visual Studio Code.app"
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
