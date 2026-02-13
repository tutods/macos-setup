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
      "/nix/store/li9dhpm0q947dkmy06dn9ln5hfflsiqm-system-applications/Applications/Visual Studio Code.app"
      "/Applications/Hyper.app"
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
