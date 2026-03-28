{...}:

let
  developmentCasks = import ./casks/development.nix;
  utilsCasks = import ./casks/utils.nix;
  webCasks = import ./casks/web.nix;
  othersCasks = import ./casks/others.nix;
in
{
  homebrew = {
    brews = [
      "smartmontools"
    ];
    casks = developmentCasks ++ utilsCasks ++ webCasks ++ othersCasks;
    masApps = import ./mas.nix;
  };
}
