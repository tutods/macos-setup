{mkDock, ...}: {
  imports = [
    (mkDock {
      groups = [
        [
          "/Applications/Firefox Developer Edition.app"
          "/Applications/Zen.app"
          "/Applications/Google Chrome.app"
          "/Applications/Safari.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
        ]
        [
          "/Applications/Zed.app"
          "/Applications/WebStorm.app"
          {home = "Applications/Home Manager Apps/Visual Studio Code.app";}
          "/Applications/Trae.app"
          "/Applications/Supacode.app"
          "/Applications/Orca.app"
          "/Applications/Ghostty.app"
        ]
      ];
    })
  ];
}
