{...}:

let
  developmentCasks   = import ./casks/development.nix;
  browserCasks       = import ./casks/browsers.nix;
  communicationCasks = import ./casks/communication.nix;
  utilsCasks         = import ./casks/utils.nix;
  fontCasks          = import ./casks/fonts.nix;
in
{
  homebrew = {
    brews = [];
    casks = developmentCasks ++ browserCasks ++ communicationCasks ++ utilsCasks ++ fontCasks;
    masApps = import ./mas.nix;
  };
}
