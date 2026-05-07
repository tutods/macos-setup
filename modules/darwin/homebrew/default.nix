{...}: let
  developmentCasks = import ./casks/development.nix;
  browserCasks = import ./casks/browsers.nix;
  communicationCasks = import ./casks/communication.nix;
  utilsCasks = import ./casks/utils.nix;
  fontsCasks = import ./casks/fonts.nix;
in {
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };

    brews = [
      "mas"
      "rtk" #  High-performance CLI proxy that reduces LLM token consumption by 60-90%
    ];

    casks = developmentCasks ++ browserCasks ++ communicationCasks ++ utilsCasks ++ fontsCasks;

    # Optional: Enable fully-declarative tap management
    # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
    mutableTaps = false;
  };
}
