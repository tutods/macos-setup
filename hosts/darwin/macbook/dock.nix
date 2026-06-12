{config, ...}: {
  system.defaults.dock = {
    persistent-apps = [
      {
        spacer = {
          small = false;
        };
      }
      "/Applications/Firefox Developer Edition.app"
      "/Applications/Zen.app"
      "/Applications/Safari.app"
      "/Applications/Google Chrome.app"
      "/System/Applications/Mail.app"
      "/System/Applications/Calendar.app"
      {
        spacer = {
          small = false;
        };
      }
      "/Applications/Zed.app"
      "/Applications/WebStorm.app"
      "/Users/${config.system.primaryUser}/Applications/Home Manager Apps/Visual Studio Code.app"
      "/Applications/Trae.app"
      "/Applications/Ghostty.app"
      {
        spacer = {
          small = false;
        };
      }
    ];
    persistent-others = [
      "/Users/${config.system.primaryUser}/Downloads"
      "/Users/${config.system.primaryUser}/Developer"
    ];
  };
}
