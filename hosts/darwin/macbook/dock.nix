{config, ...}: {
  system.defaults.dock = {
    persistent-apps = [
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
      "/Users/tutods/Downloads"
      "/Users/tutods/Developer"
    ];
  };
}
