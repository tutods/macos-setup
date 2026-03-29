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
      "/Applications/Zed.app"
      "/Users/tutods/Applications/Home Manager Apps/Visual Studio Code.app"
      "/Applications/Trae.app"
      "/Applications/Ghostty.app"
      {
        spacer = {
          small = false;
        };
      }
    ];
    persistent-others = [
      {
        path        = "/Users/tutods/Downloads";
        section     = "others";
        arrangement = 1; # Sort by Name
        displayas   = 0; # Display as Stack
        showas      = 2; # View content as Grid
      }
      "/Users/tutods/Developer"
    ];
  };
}
