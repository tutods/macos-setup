{mkDock, ...}: {
  imports = [
    (mkDock {
      groups = [
        [
          "/Applications/Brave Browser.app"
          "/Applications/Safari.app"
          "/Applications/Slack.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
        ]
        [
          "/Applications/Zed.app"
          {home = "Applications/Home Manager Apps/Visual Studio Code.app";}
          "/Applications/Orca.app"
          "/Applications/Ghostty.app"
        ]
      ];
    })
  ];
}
