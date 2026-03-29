{...}:

let
  developmentCasks  = import ./casks/development.nix;
  browserCasks      = import ./casks/browsers.nix;
  communicationCasks = import ./casks/communication.nix;
  utilsCasks        = import ./casks/utils.nix;
in
{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    global.autoUpdate = true;

    brews = [];
    casks = developmentCasks ++ browserCasks ++ communicationCasks ++ utilsCasks;
    masApps = import ./mas.nix;
  };
}
