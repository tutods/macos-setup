{mkDock, ...}: {
  imports = [
    (mkDock {
      groups = [
        [
          "/Applications/Firefox.app"
          "/Applications/Safari.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
        ]
        [
          "/Applications/Zed.app"
          "/Applications/WebStorm.app"
          {home = "Applications/Home Manager Apps/Visual Studio Code.app";}
          "/Applications/Trae.app"
          "/Applications/Orca.app"
          "/Applications/Ghostty.app"
        ]
      ];
    })
  ];
}
