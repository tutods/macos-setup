{mkDock, ...}: {
  imports = [
    (mkDock {
      groups = [
        [
          "/Applications/Firefox.app"
          "/Applications/Slack.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
        ]
        [
          "/Applications/Zed.app"
          "/Applications/WebStorm.app"
          "/Users/daniel.a.sousa/Applications/Home Manager Apps/Visual Studio Code.app"
          "/Applications/Ghostty.app"
          "/Applications/Warp.app"
        ]
      ];
    })
  ];
}
