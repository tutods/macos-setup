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
      "/Applications/Safari.app"
      "/Applications/Firefox.app"
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
      "/nix/store/li9dhpm0q947dkmy06dn9ln5hfflsiqm-system-applications/Applications/Visual Studio Code.app"
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
