{...}:

let
  developmentCasks = import ./casks/development.nix;
  utilsCasks = import ./casks/utils.nix;
  webCasks = import ./casks/web.nix;
in
{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    global.autoUpdate = true;

    brews = [
      "mas"
      "webp"
    ];
    casks = developmentCasks ++ utilsCasks ++ webCasks;
    masApps = import ./mas-apps.nix;
  };
}