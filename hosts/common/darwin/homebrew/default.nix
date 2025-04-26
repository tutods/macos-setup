{...}:

let
  developmentCasks = import ./casks-development.nix;
  utilsCasks = import ./casks-utils.nix;
  othersCasks = import ./casks-others.nix;
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
    casks = developmentCasks.casks ++ utilsCasks.casks ++ othersCasks.casks;
    masApps = {
      "Amphetamine" = 937984704;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Keynote" = 409183694;
      "Magnet" = 441258766;
      "1Blocker" = 1365531024;
      "Affinity Designer" = 824171161;
      "Affinity Photo" = 824183456;
      "Baking Soda" = 1601151613;
      "Vinegar" = 1591303229;
      "PhotoBulk" = 537211143;
      "PasteNow" = 1552536109;
      "Xnip" = 1221250572;
      "Elmedia Video Player" = 1044549675;
      "SnippetsLab" = 1006087419;
      "Tailscale" = 1475387142;
    };
  };
}