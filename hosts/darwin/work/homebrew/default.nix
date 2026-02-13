{...}:

let
  developmentCasks = import ./casks/development.nix;
  utilsCasks = import ./casks/utils.nix;
  webCasks = import ./casks/web.nix;
  othersCasks = import ./casks/others.nix;
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

    brews = [
      "mas"
      "webp"
      "qpdf"
    ];
    casks = developmentCasks ++ utilsCasks ++ webCasks ++ othersCasks;
    masApps = import ./mas.nix;
  };
}
